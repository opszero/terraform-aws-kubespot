package cmd

import (
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

func ExpandAwsSecret(secretId, str string) string {
	svc := secretsmanager.New(session.New())
	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretId),
	}

	result, err := svc.GetSecretValue(input)
	if err != nil {
		log.Println(err.Error())
		return str
	}

	// Decrypts secret using the associated KMS CMK.
	// Depending on whether the secret is a string or binary, one of these fields will be populated.
	if result.SecretString == nil {
		return str
	}

	var envConfig map[string]string
	envConfig, err = godotenv.Parse(strings.NewReader(*result.SecretString))
	if err != nil {
		log.Println(err)
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
	var fileContent string

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

		// Decrypts secret using the associated KMS CMK.
		// Depending on whether the secret is a string or binary, one of these fields will be populated.
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

	// if os.Getenv("K8S_DEPLOY_ENV_SET") == "" {
	// 	if os.Getenv("DATABASE") == "" {
	// 		//         if [ "$CIRCLE_BRANCH" = "master" ] || [ "$CIRCLE_BRANCH" = "" ]
	// 		//         then
	// 		//             DATABASE="$CIRCLE_PROJECT_REPONAME-staging"
	// 		//         else
	// 		//             DATABASE="$CIRCLE_PROJECT_REPONAME-$CIRCLE_BRANCH"
	// 		//         fi
	// 		//         DATABASE=$(echo "$DATABASE" | sed 's/[^A-Za-z0-9]/-/g')
	// 	}

	// 	if os.Getenv("CIRCLE_BRANCH") == "master" || os.Getenv("CIRCLE_BRANCH") == "" {
	// 		// set staging related data
	// 		log.Println("configuring staging env")
	// 	} else {
	// 		// set feature deployment data
	// 		log.Println("configuring feature deployment env")
	// 		//         HELM_NAME=$(echo $CIRCLE_BRANCH-$CHART_NAME | sed 's/[^A-Za-z0-9]/-/g' | tr '[:upper:]' '[:lower:]')
	// 	}

	// 	//     export CLOUD_PROVIDER=${CLOUD_PROVIDER:-"aws"}
	// 	//     export SUBDOMAIN=${SUBDOMAIN:-$HELM_NAME}
	// 	//     export DOMAIN=${DOMAIN:-"opszero.com"}
	// 	//     export HOST="$SUBDOMAIN.$DOMAIN"
	// 	//     export URL_HOST="https://$HOST"
	// 	//     export CIRCLE_BRANCH=$(echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9_]/-/g')

	// 	//     export K8S_DEPLOY_ENV_SET=true

	// }

	os.Setenv("CIRCLE_BRANCH", c.circleBranch())

	os.Setenv("CONTAINER_REGISTRY", c.Docker.Build.ContainerRegistry)
	os.Setenv("PROJECT_ID", c.Docker.Build.ProjectId)

	if os.Getenv("CIRCLE_BRANCH") == "master" {
		os.Setenv("DOCKER_TAG", "latest")
	} else {
		os.Setenv("DOCKER_TAG", os.Getenv("CIRCLE_BRANCH"))
	}

	c.DockerLogin()

	c.KuberneteConfig()
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
		branchImage = c.dockerCircleImageWithSuffix(image, os.Getenv("CIRCLE_BRANCH"))
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

	if os.Getenv("CIRCLE_BRANCH") == "master" {
		c.runCmd("docker", "tag", image, latestImage)
		c.runCmd("docker", "push", latestImage)
	}
}

func (c *Config) circleBranch() string {
	return strings.TrimSpace(strings.ToLower(c.runCmdOutput("bash", "-c", os.ExpandEnv("echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9_]/-/g'"))))
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
	os.Setenv("CHART_NAME", c.Docker.Deploy.ChartName)

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

	envConfig := string(b)
	for _, i := range c.Docker.Deploy.AwsSecretsIds {
		envConfig = ExpandAwsSecret(i, envConfig)
	}
	ioutil.WriteFile(envFile, []byte(envConfig), 0644)

	log.Println(envConfig)

	os.Setenv("HELM_HOME", c.runCmdOutput("helm", "home"))
	os.MkdirAll(os.Getenv("HELM_HOME"), os.ModePerm)

	if os.Getenv("HELM_TLS") != "" {
		// 	if [ ! -f $HELM_HOME/ca.pem ]
		// 	then
		// 		echo "$HELM_CA" | base64 -d --ignore-garbage > $HELM_HOME/ca.pem
		// 	fi

		// 	if [ ! -f $HELM_HOME/cert.pem ]
		// 	then
		// 		echo "$HELM_CERT"| base64 -d --ignore-garbage > $HELM_HOME/cert.pem
		// 	fi

		// 	if [ ! -f $HELM_HOME/key.pem ]
		// 	then
		// 		echo "$HELM_KEY"| base64 -d --ignore-garbage > $HELM_HOME/key.pem
		// 	fi
		// 	HELM_ARGS+=(--tls)

	}

	var helmArgs []string

	if os.Getenv("CIRCLE_BRANCH") == "master" || os.Getenv("CIRCLE_BRANCH") == "" {
		log.Println("Deploying")
	} else {
		helmArgs = append(helmArgs, "--namespace", os.Getenv("CIRCLE_BRANCH"))
		c.runCmd("kubectl", "create", "namespace", os.Getenv("CIRCLE_BRANCH"))
	}

	if os.Getenv("TILLER_NAMESPACE") == "" {
		os.Setenv("TILLER_NAMESPACE", "kube-system")
	}

	helmArgs = append(helmArgs,
		// "--set",
		// os.ExpandEnv("ingress.hosts={$HOST}"),
		// "--set",
		// os.ExpandEnv("ingress.tls[0].hosts={$HOST}"),
		// "--set",
		// os.ExpandEnv("ingress.tls[0].secretName=$HELM_NAME-staging-cert"),
		"--set", os.ExpandEnv("image.tag=${CIRCLE_SHA1}"),
		"--set", fmt.Sprintf("deploytag.tag=%s", os.Getenv("DOCKER_TAG")),
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

	// if [ -n "$HELM_VARS" ]
	// then
	// 	HELM_ARGS+=($(echo "$HELM_VARS" | envsubst))
	// fi

	c.runCmd(append([]string{"helm", "upgrade", c.circleBranch(), os.Getenv("CHART_NAME"), "-f", envFile}, helmArgs...)...)
}

// func (c *Config) DeployDns() {
// 	if os.Getenv("CF_API_KEY") != "" && os.Getenv("CF_API_EMAIL") != "" && os.Getenv("CF_API_DOMAIN") {
// 		log.Println("Setting DNS on Cloudflare")
// 	} else {
// 		return
// 	}

// 	api, err := cloudflare.New(os.Getenv("CF_API_KEY"), os.Getenv("CF_API_EMAIL"))
// 	if err != nil {
// 		log.Fatal(err)
// 	}

// 	zoneID, err := api.ZoneIDByName(os.Getenv("CF_API_DOMAIN"))
// 	if err != nil {
// 		log.Fatal(err)
// 	}

// 	// if aws CNAME
// 	// if gcp A
// 	recs, err := api.DNSRecords(zoneID, cloudflare.DNSRecord{
// 		Name: fmt.Sprintf("%s-%s.%s", os.Getenv("DOCKER_TAG"), strings.ToLower(c.Cloud), os.Getenv("CF_API_DOMAIN")),
// 		Type: "CNAME"
// 	})
// 	if err != nil {
// 		log.Fatal(err)
// 	}

// 	recs.
// 	// If it doesn't exist create it
// 	// Else Update it
// }

func (c *Config) RunScript() {
	pod := c.runCmdOutput("bash", "-c", fmt.Sprintf("kubectl get pod -n %s --selector=app=%s -o jsonpath='{.items[0].metadata.name}'", c.circleBranch(), c.Docker.RunScript.PodAppLabel))

	for _, i := range c.Docker.RunScript.Cmds {
		c.runCmd("kubectl", "exec", "-i", pod, "-n", c.circleBranch(), "--", i)
	}
}
