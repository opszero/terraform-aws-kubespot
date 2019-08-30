package cmd

import (
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/secretsmanager"

	"github.com/a8m/envsubst"
	"github.com/joho/godotenv"
	"gopkg.in/yaml.v2"
)

const (
	AwsCloud   = "aws"
	GcpCloud   = "gcp"
	AzureCloud = "azure"
)

type Config struct {
	Cloud            string
	CloudAwsSecretId string

	AWSAccessKeyID     string
	AWSSecretAccessKey string
	AWSDefaultRegion   string

	GCPServiceKeyFile   string
	GCPServiceKeyBase64 string
	// GOOGLE_PROJECT_ID=alien-clover-238521 GOOGLE_COMPUTE_ZONE=us-central1 GOOGLE_CLUSTER_NAME=qa-us-central1

	// Text of
	// export ENV=env
	// ...
	EnvConfig map[string]string

	Docker struct {
		Build struct {
			DotEnvFile    string
			AwsSecretsIds []string

			ContainerRegistry string
			ProjectId         string
			Image             string
		}

		Deploy struct {
			AwsSecretsIds []string
			Env           string
			HelmConfig    string
			ChartName     string
			HelmSet       []string
		}

		RunScript struct {
			PodAppLabel string
			Container   string
			Cmds        []string
		}
	}
}

func (c *Config) runCmd(cmdArgs ...string) error {
	log.Println("Running", cmdArgs)

	var args []string
	if len(cmdArgs) > 1 {
		args = cmdArgs[1:len(cmdArgs)]
	}
	log.Println("Args", args)
	cmd := exec.Command(cmdArgs[0], args...)

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		//log.Fatalf("runCmd failed with %s\n", err)
		return err
	}

	return nil
}

func (c *Config) runCmdOutput(cmdArgs ...string) string {
	log.Println("Running", cmdArgs)

	var args []string
	if len(cmdArgs) > 1 {
		args = cmdArgs[1:len(cmdArgs)]
	}
	log.Println("Args", args)
	cmd := exec.Command(cmdArgs[0], args...)
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}
	return fmt.Sprintf("%s", stdoutStderr)
}

func (c *Config) getAwsSecretForCloud(secretId string) {
	svc := secretsmanager.New(session.New())
	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretId),
	}

	result, err := svc.GetSecretValue(input)
	if err != nil {
		log.Println(err.Error())
		return
	}

	log.Println("Secret Result", result)
	// Decrypts secret using the associated KMS CMK.
	// Depending on whether the secret is a string or binary, one of these fields will be populated.
	if result.SecretString == nil {
		return
	}

	c.EnvConfig, err = godotenv.Parse(strings.NewReader(*result.SecretString))
	if err != nil {
		log.Println(err)
	}

	log.Println("Config", c.EnvConfig)

	for k := range c.EnvConfig {
		log.Println("Setting up var", k)
		os.Setenv(k, c.EnvConfig[k])
	}
}

func AwsSecretsAsDotEnv(secretIds []string) (fileContent string) {
	for _, secretId := range secretIds {
		svc := secretsmanager.New(session.New())
		input := &secretsmanager.GetSecretValueInput{
			SecretId: aws.String(secretId),
		}

		result, err := svc.GetSecretValue(input)
		if err != nil {
			log.Println(err.Error())
			continue
		}

		// Decrypts secret using the associated KMS CMK.
		// Depending on whether the secret is a string or binary, one of these fields will be populated.
		if result.SecretString == nil {
			continue
		}

		fileContent += fmt.Sprintf("# %s", secretId)
		fileContent += "\n"
		fileContent += *result.SecretString
		fileContent += "\n\n"
	}

	return
}
func ExpandAwsSecrets(secretIds []string, str string) string {
	envConfig := make(map[string]string)

	for _, secretId := range secretIds {
		svc := secretsmanager.New(session.New())
		input := &secretsmanager.GetSecretValueInput{
			SecretId: aws.String(secretId),
		}

		result, err := svc.GetSecretValue(input)
		if err != nil {
			log.Println(err.Error())
			continue
		}

		// Decrypts secret using the associated KMS CMK.
		// Depending on whether the secret is a string or binary, one of these fields will be populated.
		if result.SecretString == nil {
			continue
		}

		var e map[string]string
		e, err = godotenv.Parse(strings.NewReader(*result.SecretString))
		if err != nil {
			log.Println(err)
		}

		for key, value := range e {
			envConfig[key] = value
		}
	}

	mapper := func(placeholderName string) string {
		if s, ok := envConfig[placeholderName]; ok {
			return fmt.Sprintf("'%s'", s)
		}

		return "''"
	}

	return os.Expand(str, mapper)
}

func (c *Config) writeAwsSecrets(fileName string, secretIds []string) {
	var (
		fileContent string
	)

	fileContent += fmt.Sprintf("\n\nDEPLOYTAG_BRANCH=%s\n\n", c.circleBranch())

	for _, secretId := range secretIds {
		svc := secretsmanager.New(session.New())
		input := &secretsmanager.GetSecretValueInput{
			SecretId: aws.String(secretId),
		}

		result, err := svc.GetSecretValue(input)
		if err != nil {
			log.Println(err.Error())
			return
		}

		fileContent += fmt.Sprintf("# %s", secretId)
		fileContent += "\n"
		fileContent += *result.SecretString
		fileContent += "\n\n"
	}

	log.Println("Writing .env", fileContent)

	err := ioutil.WriteFile(fileName, []byte(fileContent), 0644)
	if err != nil {
		log.Println(err)
	}
}

func (c *Config) Init() {
	if c.CloudAwsSecretId != "" {
		log.Println("Loading Secrets")
		c.getAwsSecretForCloud(c.CloudAwsSecretId)
	}

	log.Println(os.Getenv("PATH"))
	switch strings.ToLower(c.Cloud) {
	case AwsCloud:
		if c.AWSAccessKeyID == "" || c.AWSSecretAccessKey == "" || c.AWSDefaultRegion == "" {
			log.Fatalf("Ensure that AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_DEFAULT_REGION are set")
		}
	case GcpCloud:
		if os.Getenv("GCLOUD_SERVICE_KEY_BASE64") != "" {
			c.runCmd("bash", "-c", "echo $GCLOUD_SERVICE_KEY_BASE64 | base64 -d > /tmp/gcloud-service-key.json")
		} else {
			log.Fatal("No Google Service Account Key given")
		}

		c.runCmd("gcloud", "auth", "activate-service-account", "--key-file=/tmp/gcloud-service-key.json")
	case AzureCloud:

	default:
		log.Fatalf("Invalid Cloud")
	}

	os.Setenv("CONTAINER_REGISTRY", c.Docker.Build.ContainerRegistry)
	os.Setenv("PROJECT_ID", c.Docker.Build.ProjectId)

	os.Setenv("CIRCLE_BRANCH", c.circleBranch())
	os.Setenv("DEPLOYTAG_BRANCH", c.circleBranch())
	if c.circleBranch() == "master" {
		log.Println("configuring production env")
		os.Setenv("DOCKER_TAG", "latest")
	} else {

		log.Println("configuring staging env")
		os.Setenv("DOCKER_TAG", c.circleBranch())
	}

	c.DockerLogin()
	c.KuberneteConfig()

	log.Println("Circle Branch", c.circleBranch())
}

func (c *Config) DockerLogin() {
	log.Println("Docker Login")
	switch strings.ToLower(c.Cloud) {
	case GcpCloud:
		c.runCmd("bash", "-c", fmt.Sprintf("gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://%s", c.Docker.Build.ContainerRegistry))
	case AwsCloud:
		loginCmd := c.runCmdOutput("aws", "ecr", "get-login", "--no-include-email")
		c.runCmd("bash", "-c", loginCmd)
	}
}

func (c *Config) KuberneteConfig() {
	switch strings.ToLower(c.Cloud) {
	case GcpCloud:
		c.runCmd("gcloud", "--quiet", "config", "set", "project", os.Getenv("GOOGLE_PROJECT_ID"))
		c.runCmd("gcloud", "--quiet", "config", "set", "compute/zone", os.Getenv("GOOGLE_COMPUTE_ZONE"))
		c.runCmd("gcloud", "auth", "configure-docker", "--quiet")
		c.runCmd("gcloud", "--quiet", "container", "clusters", "get-credentials", os.ExpandEnv("${GOOGLE_CLUSTER_NAME}"))
	case AwsCloud:
		c.runCmd("aws", "eks", "--region", os.ExpandEnv("${AWS_DEFAULT_REGION}"), "update-kubeconfig", "--name", os.ExpandEnv("${AWS_CLUSTER_NAME}"))
	}
}

func (c *Config) dockerCircleImageWithSuffix(image, suffix string) string {
	return strings.TrimSpace(fmt.Sprintf("%s/%s/%s:%s", c.Docker.Build.ContainerRegistry, c.Docker.Build.ProjectId, image, suffix))
}

func (c *Config) dockerCircleImage(image string) string {
	return strings.TrimSpace(fmt.Sprintf("%s/%s/%s", c.Docker.Build.ContainerRegistry, c.Docker.Build.ProjectId, image))
}

func (c *Config) DockerBuildImage(image, dockerfile string) {
	var (
		shaImage    = c.dockerCircleImageWithSuffix(image, os.Getenv("CIRCLE_SHA1"))
		branchImage = c.dockerCircleImageWithSuffix(image, c.circleBranch())
		latestImage = c.dockerCircleImageWithSuffix(image, "latest")
	)

	log.Println("Docker Build Image")

	if c.Docker.Build.DotEnvFile != "" {
		log.Println("Writing .env file")
		c.writeAwsSecrets(c.Docker.Build.DotEnvFile, c.Docker.Build.AwsSecretsIds)
	}

	buildCmd := []string{"docker", "build"}
	if os.Getenv("DOCKER_BUILD_ARGS") != "" {
		buildCmd = append(buildCmd, os.Getenv("DOCKER_BUILD_ARGS"))
	}
	buildCmd = append(buildCmd, "-t", image, "-f", dockerfile, ".")
	err := c.runCmd(buildCmd...)
	if err != nil {
		log.Fatal("Couldn't build image")
	}

	c.runCmd("docker", "tag", image, shaImage)
	c.runCmd("docker", "push", shaImage)

	c.runCmd("docker", "tag", image, branchImage)
	c.runCmd("docker", "push", branchImage)

	if c.circleBranch() == "master" {
		c.runCmd("docker", "tag", image, latestImage)
		c.runCmd("docker", "push", latestImage)
	}
}

func (c *Config) circleBranch() string {
	return strings.TrimSpace(strings.ToLower(c.runCmdOutput("bash", "-c", os.ExpandEnv("echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9]/-/g'"))))
}

func (c *Config) DockerBuild() {
	subset, err := envsubst.ReadFile("Dockerfile")
	if err != nil {
		log.Println(err)
	}
	err = ioutil.WriteFile("Dockerfile.sub", subset, 0644)
	if err != nil {
		log.Println(err)
	}

	c.DockerBuildImage(c.Docker.Build.Image, "Dockerfile.sub")
}

func (c *Config) Deploy() {
	b, err := ioutil.ReadFile(c.Docker.Deploy.HelmConfig)
	if err != nil {
		log.Fatal(err)
	}

	t := make(map[string]interface{})
	err = yaml.Unmarshal([]byte(b), t)
	if err != nil {
		log.Fatal(err)
	}

	b, err = yaml.Marshal(t[c.Docker.Deploy.Env])
	if err != nil {
		log.Fatal(err)
	}

	envFile := c.Docker.Deploy.Env + ".yml"

	envMap := make(map[string]string)
	envMap["DEPLOYTAG_DOTENV"] = base64.StdEncoding.EncodeToString([]byte(AwsSecretsAsDotEnv(c.Docker.Deploy.AwsSecretsIds)))

	envConfig := os.Expand(string(b), func(placeholderName string) string {
		if s, ok := envMap[placeholderName]; ok {
			return fmt.Sprintf("%s", s)
		}

		return "''"
	})

	ioutil.WriteFile(envFile, []byte(envConfig), 0644)

	log.Println(string(envConfig))

	os.Setenv("HELM_HOME", c.runCmdOutput("helm", "home"))
	os.MkdirAll(os.Getenv("HELM_HOME"), os.ModePerm)

	var helmArgs []string

	if c.circleBranch() == "master" || c.circleBranch() == "" {
		log.Println("Deploying")
	} else {
		helmArgs = append(helmArgs, "--namespace", c.circleBranch())
		c.runCmd("kubectl", "create", "namespace", c.circleBranch())
	}

	if os.Getenv("TILLER_NAMESPACE") == "" {
		os.Setenv("TILLER_NAMESPACE", "kube-system")
	}

	helmArgs = append(helmArgs,
		"--set", os.ExpandEnv("image.tag=${CIRCLE_SHA1}"),
		"--set", fmt.Sprintf("deploytag.tag=%s", os.Getenv("DOCKER_TAG")),
		"--set", fmt.Sprintf("deploytag.cloud=%s", c.Cloud),
	)

	for _, i := range c.Docker.Deploy.HelmSet {
		helmArgs = append(helmArgs, "--set", i)
	}

	helmArgs = append(helmArgs,
		os.ExpandEnv("--tiller-namespace=$TILLER_NAMESPACE"),
		"--force",
		"--recreate-pods",
		// "--wait", TODO: Undo.
		"--install")

	c.runCmd(append([]string{"helm", "upgrade", c.circleBranch(), c.Docker.Deploy.ChartName, "-f", envFile}, helmArgs...)...)
}

func (c *Config) RunScript() {
	pod := c.runCmdOutput("bash", "-c", fmt.Sprintf("kubectl get pod -n %s --selector=app=%s -o jsonpath='{.items[0].metadata.name}'", c.circleBranch(), c.Docker.RunScript.PodAppLabel))

	for _, i := range c.Docker.RunScript.Cmds {
		c.runCmd("kubectl", "exec", "-i", pod, "-n", c.circleBranch(), "-c", c.Docker.RunScript.Container, "--", i)
	}
}
