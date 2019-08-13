package cmd

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"strconv"
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
			ContainerRegistry string
			ProjectId         string
			Image             string
		}

		Deploy struct {
			AwsSecretsIds []string
			Env           string
			HelmConfig    string
			ChartName     string
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
		//     if [ -n "$GCLOUD_SERVICE_KEY"]
		//     then
		//         echo $GCLOUD_SERVICE_KEY > $HOME/gcloud-service-key.json
		//     elif [ -n "$GCLOUD_SERVICE_KEY_BASE64" ]
		//     then
		//         echo $GCLOUD_SERVICE_KEY_BASE64 | base64 -d > $HOME/gcloud-service-key.json
		//     else
		//         echo "No Google Service Account Key given"
		//     fi
		c.runCmd("gcloud", "auth", "activate-service-account", fmt.Sprintf("--key-file=%s", c.GCPServiceKeyFile))
	case AzureCloud:

	default:
		log.Fatalf("Invalid Cloud")
	}

	if os.Getenv("K8S_DEPLOY_ENV_SET") == "" {
		if os.Getenv("DATABASE") == "" {
			//         if [ "$CIRCLE_BRANCH" = "master" ] || [ "$CIRCLE_BRANCH" = "" ]
			//         then
			//             DATABASE="$CIRCLE_PROJECT_REPONAME-staging"
			//         else
			//             DATABASE="$CIRCLE_PROJECT_REPONAME-$CIRCLE_BRANCH"
			//         fi
			//         DATABASE=$(echo "$DATABASE" | sed 's/[^A-Za-z0-9]/-/g')
		}

		if os.Getenv("CIRCLE_BRANCH") == "master" || os.Getenv("CIRCLE_BRANCH") == "" {
			// set staging related data
			log.Println("configuring staging env")
		} else {
			// set feature deployment data
			log.Println("configuring feature deployment env")
			//         HELM_NAME=$(echo $CIRCLE_BRANCH-$CHART_NAME | sed 's/[^A-Za-z0-9]/-/g' | tr '[:upper:]' '[:lower:]')
		}

		//     export CLOUD_PROVIDER=${CLOUD_PROVIDER:-"aws"}
		//     export SUBDOMAIN=${SUBDOMAIN:-$HELM_NAME}
		//     export DOMAIN=${DOMAIN:-"opszero.com"}
		//     export HOST="$SUBDOMAIN.$DOMAIN"
		//     export URL_HOST="https://$HOST"
		//     export CIRCLE_BRANCH=$(echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9_]/-/g')

		//     export K8S_DEPLOY_ENV_SET=true

	}

	os.Setenv("CIRCLE_BRANCH", c.circleBranch())
}

func (c *Config) DockerShouldBuildBase() bool {
	// 	# If a Dockerfile.base exists
	if _, err := os.Stat("Dockerfile.base"); err == nil {
		switch {
		case c.DockerHasBaseImage() == false:
			return true
		case os.Getenv("FORCE_BASE_BUILD") != "":
			return true
		default:
			// Otherwise compare the Dockerfile.base with the latest sha
			baseCommit := c.runCmdOutput("git", "log", "-1", "--format=format:%H", "--full-diff", "Dockerfile.base")
			return baseCommit == os.Getenv("CIRCLE_SHA1")
		}
	}

	return true
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

func (c *Config) DockerHasBaseImage() bool {
	var countStr string

	switch strings.ToLower(c.Cloud) {
	case GcpCloud:
		countStr = c.runCmdOutput("bash", "-c", os.ExpandEnv("gcloud container images list-tags --filter=\"tags=($CIRCLE_BRANCH)\" --format=\"table[no-heading](digest)\" \"${CONTAINER_REGISTRY}/${PROJECT_ID}/${BASE_IMAGE}\" | wc -l"))
	case AwsCloud:
		countStr = c.runCmdOutput("bash", "-c", os.ExpandEnv("aws ecr describe-images --repository-name \"${PROJECT_ID}/${BASE_IMAGE}\" --image-ids=\"imageTag=${CIRCLE_BRANCH}\" | grep imageDetails | wc -l"))
	}

	log.Println("Base Image Count", countStr)

	i, err := strconv.Atoi(strings.TrimSpace(countStr))
	if err != nil {
		log.Println(err)
		return false
	}
	return i > 0
}

func (c *Config) dockerCircleImageWithSuffix(image, suffix string) string {
	return strings.TrimSpace(fmt.Sprintf("%s/%s/%s:%s", c.Docker.Build.ContainerRegistry, c.Docker.Build.ProjectId, image, suffix))
}

func (c *Config) DockerBuildImage(image, dockerfile string) {
	var (
		shaImage    = c.dockerCircleImageWithSuffix(image, os.Getenv("CIRCLE_SHA1"))
		branchImage = c.dockerCircleImageWithSuffix(image, os.Getenv("CIRCLE_BRANCH"))
		latestImage = c.dockerCircleImageWithSuffix(image, "latest")
	)

	log.Println("Docker Build Image")

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
	os.Setenv("CONTAINER_REGISTRY", c.Docker.Build.ContainerRegistry)
	os.Setenv("PROJECT_ID", c.Docker.Build.ProjectId)

	baseImage := fmt.Sprintf("%s_base", c.Docker.Build.Image)
	os.Setenv("BASE_IMAGE", baseImage)

	if os.Getenv("CIRCLE_BRANCH") == "master" {
		os.Setenv("DOCKER_TAG", "latest")
	} else {
		os.Setenv("DOCKER_TAG", os.Getenv("CIRCLE_BRANCH"))
	}

	c.DockerLogin()
	// If we've created a base image for this branch, let's use it. Otherwise use the latest base image.
	if c.DockerShouldBuildBase() {
		c.DockerBuildImage(baseImage, "./Dockerfile.base")
	}

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

func (c *Config) KubernetesApplyDockerRegistrySecrets() {
	// if [ "$CLOUD_PROVIDER" = "gcp" ]
	// then
	// 	kubectl get secret gcrsecret --export -o yaml | kubectl apply -n $CIRCLE_BRANCH -f -
	// 	kubectl patch serviceaccount default -n $CIRCLE_BRANCH -p '{"imagePullSecrets": [{"name": "gcrsecret"}]}'
	// elif [ "$CLOUD_PROVIDER" = "aws" ]
	// then
	// 	# kubectl get secret ecrsecret --export -o yaml | kubectl apply -n $CIRCLE_BRANCH -f -
	// 	# kubectl patch serviceaccount default -n $CIRCLE_BRANCH -p '{"imagePullSecrets": [{"name": "ecrsecret"}]}'
	// 	echo "EKS has native support to pull from ECR"
	// fi
}

func (c *Config) KuberneteConfig() {
	switch strings.ToLower(c.Cloud) {
	case GcpCloud:
		// 	gcloud --quiet config set project ${GOOGLE_PROJECT_ID}
		// 	gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE}
	// 	gcloud --quiet container clusters get-credentials ${GOOGLE_CLUSTER_NAME}
	case AwsCloud:
		c.runCmd("aws", "eks", "--region", os.ExpandEnv("${AWS_DEFAULT_REGION}"), "update-kubeconfig", "--name", os.ExpandEnv("${AWS_CLUSTER_NAME}"))
	}
}

func (c *Config) Deploy() {
	c.KuberneteConfig()

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

	var helmArgs []string

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

	if os.Getenv("CIRCLE_BRANCH") == "master" || os.Getenv("CIRCLE_BRANCH") == "" {
		log.Println("Deploying")
	} else {
		helmArgs = append(helmArgs, "--namespace", os.Getenv("CIRCLE_BRANCH"))
		c.runCmd("kubectl", "create", "namespace", os.Getenv("CIRCLE_BRANCH"))
		c.KubernetesApplyDockerRegistrySecrets()
	}

	if os.Getenv("TILLER_NAMESPACE") == "" {
		os.Setenv("TILLER_NAMESPACE", "kube-system")
	}

	helmArgs = append(helmArgs,
		"--set",
		os.ExpandEnv("ingress.hosts={$HOST}"),
		"--set",
		os.ExpandEnv("ingress.tls[0].hosts={$HOST}"),
		"--set",
		os.ExpandEnv("ingress.tls[0].secretName=$HELM_NAME-staging-cert"),
		"--set",
		os.ExpandEnv("image.tag=${CIRCLE_SHA1}"),
		os.ExpandEnv("--tiller-namespace=$TILLER_NAMESPACE"),
		"--force",
		"--wait",
		"--install")

	// if [ -n "$HELM_VARS" ]
	// then
	// 	HELM_ARGS+=($(echo "$HELM_VARS" | envsubst))
	// fi

	c.runCmd(append([]string{"helm", "upgrade", c.circleBranch(), os.Getenv("CHART_NAME"), "-f", envFile}, helmArgs...)...)
}

func (c *Config) RunScript() {
	pod := c.runCmdOutput("bash", "-c", fmt.Sprintf("kubectl get pod -n %s --selector=app=%s -o jsonpath='{.items[0].metadata.name}'", c.circleBranch(), c.Docker.RunScript.PodAppLabel))

	for _, i := range c.Docker.RunScript.Cmds {
		c.runCmd("kubectl", "exec", "-i", pod, "-n", c.circleBranch(), "--", i)
	}
}
