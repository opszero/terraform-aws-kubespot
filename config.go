package main

import (
	"bytes"
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"strings"
	"text/template"

	"github.com/cloudflare/cloudflare-go"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/secretsmanager"

	"github.com/a8m/envsubst"
	"github.com/joho/godotenv"
)

const (
	CloudFlareEmail  = "CLOUDFLARE_EMAIL"
	CloudFlareAPIKey = "CLOUDFLARE_APIKEY"
	CloudFlareDomain = "CLOUDFLARE_DOMAIN"
	CloudFlareZoneID = "CLOUDFLARE_ZONE_ID"
)

const (
	LoadBalancerCommand = "kubectl get svc ingress-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
)

const (
	AwsCloud   = "aws"
	GcpCloud   = "gcp"
	AzureCloud = "azure"
)

type Config struct {
	Cloud            string
	CloudAwsSecretId string
	CloudEnvConfig   map[string]string

	AWSAccessKeyID     string
	AWSSecretAccessKey string
	AWSDefaultRegion   string

	GCPServiceKeyFile   string
	GCPServiceKeyBase64 string

	AppAwsSecretIds []string
	AppEnvConfig    string

	CloudFlareEmail    string
	CloudFlareKey      string
	CloudFlareZoneName string
	CloudFlareZoneID   string
	ExternalHostNames  []string

	Build struct {
		DotEnvFile string

		ContainerRegistry string
		ProjectId         string
		Image             string
	}

	Deploy struct {
		ChartName string
		HelmSet   []string
	}

	RunScript struct {
		PodAppLabel string
		Container   string
		Cmds        []string
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
		args = cmdArgs[1:]
	}
	log.Println("Args", args)
	cmd := exec.Command(cmdArgs[0], args...)
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatal(err)
	}
	return fmt.Sprintf("%s", stdoutStderr)
}

func (c *Config) loadCloudAwsSecrets() {
	if c.CloudAwsSecretId == "" {
		return
	}

	log.Println("Loading Cloud Secrets")

	svc := secretsmanager.New(session.New())
	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(c.CloudAwsSecretId),
	}

	result, err := svc.GetSecretValue(input)
	if err != nil {
		log.Println(err.Error())
		return
	}

	if result.SecretString == nil {
		return
	}

	c.CloudEnvConfig, err = godotenv.Parse(strings.NewReader(*result.SecretString))
	if err != nil {
		log.Println(err)
	}

	log.Println("Cloud Config", c.CloudEnvConfig)

	for k := range c.CloudEnvConfig {
		log.Println("Setting up var", k)
		os.Setenv(k, c.CloudEnvConfig[k])
	}
}

func (c *Config) loadAppAwsSecrets() {
	fileContent := fmt.Sprintf("DEPLOYTAG_BRANCH=%s\n\n", c.circleBranch())

	for _, secretId := range c.AppAwsSecretIds {
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

	c.AppEnvConfig = fileContent

	log.Println(c.AppEnvConfig)

	return
}

func (c *Config) writeAppAwsSecrets(fileName string) {
	log.Println("Writing .env", c.AppEnvConfig)

	err := ioutil.WriteFile(fileName, []byte(c.AppEnvConfig), 0644)
	if err != nil {
		log.Println(err)
	}
}

func (c *Config) Init() {
	c.loadAppAwsSecrets()
	c.loadCloudAwsSecrets()

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
		c.runCmd("az", "login", "--service-principal", "--tenant", os.Getenv("AZURE_SERVICE_PRINCIPAL_TENANT"), "--username", os.Getenv("AZURE_SERVICE_PRINCIPAL"), "--password", os.Getenv("AZURE_SERVICE_PRINCIPAL_PASSWORD"))
	default:
		log.Fatalf("Invalid Cloud")
	}

	os.Setenv("CONTAINER_REGISTRY", c.Build.ContainerRegistry)
	os.Setenv("PROJECT_ID", c.Build.ProjectId)

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

	c.CloudFlareKey = os.Getenv(CloudFlareAPIKey)
	c.CloudFlareEmail = os.Getenv(CloudFlareEmail)
	c.CloudFlareZoneName = os.Getenv(CloudFlareDomain)
	c.CloudFlareZoneID = os.Getenv(CloudFlareZoneID)

	log.Println(c.CloudFlareKey, c.CloudFlareEmail, c.CloudFlareZoneName, c.CloudFlareZoneID)

	log.Println("Circle Branch", c.circleBranch())
}

func (c *Config) DockerLogin() {
	log.Println("Docker Login")
	switch strings.ToLower(c.Cloud) {
	case GcpCloud:
		c.runCmd("bash", "-c", fmt.Sprintf("gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://%s", c.Build.ContainerRegistry))
	case AwsCloud:
		c.runCmd("bash", "-c", c.runCmdOutput("aws", "ecr", "get-login", "--no-include-email"))
	case AzureCloud:
		name := strings.TrimSpace(c.runCmdOutput("bash", "-c", os.ExpandEnv("echo $AZURE_CLUSTER_NAME | sed 's/[^A-Za-z0-9]//g'")))
		log.Println("Azure Cluster", name)
		c.runCmd("az", "acr", "login", "--name", name)
		c.Build.ContainerRegistry = strings.TrimSpace(c.runCmdOutput("bash", "-c", os.ExpandEnv("az acr list --resource-group $AZURE_RESOURCE_GROUP --query '[].{acrLoginServer:loginServer}' --output json | jq -r '.[].acrLoginServer'")))
		log.Println("Azure ContainerRegistry", c.Build.ContainerRegistry)
	}
}

func (c *Config) KuberneteConfig() {
	switch strings.ToLower(c.Cloud) {
	case GcpCloud:
		c.runCmd("gcloud", "--quiet", "config", "set", "project", os.Getenv("GOOGLE_PROJECT_ID"))
		c.runCmd("gcloud", "--quiet", "config", "set", "compute/zone", os.Getenv("GOOGLE_COMPUTE_ZONE"))
		c.runCmd("gcloud", "auth", "configure-docker", "--quiet")
		c.runCmd("gcloud", "--quiet", "container", "clusters", "get-credentials", os.Getenv("GOOGLE_CLUSTER_NAME"))
	case AwsCloud:
		c.runCmd("aws", "eks", "--region", os.Getenv("AWS_DEFAULT_REGION"), "update-kubeconfig", "--name", os.Getenv("AWS_CLUSTER_NAME"))
	case AzureCloud:
		c.runCmd("az", "aks", "get-credentials", "--resource-group", os.Getenv("AZURE_RESOURCE_GROUP"), "--name", os.Getenv("AZURE_CLUSTER_NAME"), "--overwrite-existing")
	}
}

func (c *Config) dockerCircleImageWithSuffix(image, suffix string) string {
	return strings.TrimSpace(fmt.Sprintf("%s/%s/%s:%s", c.Build.ContainerRegistry, c.Build.ProjectId, image, suffix))
}

func (c *Config) dockerCircleImage(image string) string {
	return strings.TrimSpace(fmt.Sprintf("%s/%s/%s", c.Build.ContainerRegistry, c.Build.ProjectId, image))
}

func (c *Config) DockerBuildImage(image, dockerfile string) {
	var (
		shaImage    = c.dockerCircleImageWithSuffix(image, os.Getenv("CIRCLE_SHA1"))
		branchImage = c.dockerCircleImageWithSuffix(image, c.circleBranch())
		latestImage = c.dockerCircleImageWithSuffix(image, "latest")
	)

	log.Println("Docker Build Image")

	if c.Build.DotEnvFile != "" {
		log.Println("Writing .env file")
		c.writeAppAwsSecrets(c.Build.DotEnvFile)
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

	c.DockerBuildImage(c.Build.Image, "Dockerfile.sub")
}

func (c *Config) HelmDeploy() {
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
		"--set", fmt.Sprintf("secrets.files.dotenv.dotenv=%s", base64.StdEncoding.EncodeToString([]byte(c.AppEnvConfig))),
	)

	for _, i := range c.Deploy.HelmSet {
		helmArgs = append(helmArgs, "--set", i)
	}

	helmArgs = append(helmArgs,
		os.ExpandEnv("--tiller-namespace=$TILLER_NAMESPACE"),
		"--force",
		"--recreate-pods",
		// "--wait", TODO: Undo.
		"--install")

	c.runCmd(append([]string{"helm", "upgrade", c.circleBranch(), c.Deploy.ChartName}, helmArgs...)...)

	// TODO should exec from output or use something like this https://github.com/kubernetes/client-go/blob/master/examples/out-of-cluster-client-configuration/main.go#L74
	loadBalancerURL := c.runCmdOutput("bash", "-c", LoadBalancerCommand)

	if err := c.CloudflareDnsDeploy(loadBalancerURL); err != nil {
		log.Println(err.Error())
	}
}

func contains(s []string, e string) bool {
	for _, a := range s {
		if a == e {
			return true
		}
	}
	return false
}

// Documentation for record types are found here https://api.cloudflare.com/#dns-records-for-a-zone-create-dns-record
// this will error out if the api is configured incorrectly, cannot fetch DNS records of zone or the zones themselves, or if
// it cannot create a DNS record (note: not update a record)
func (c *Config) CloudflareDnsDeploy(loadbalancer string) error {
	var (
		cloudflareEmail  = os.Getenv(CloudFlareEmail)
		cloudflareAPIKey = os.Getenv(CloudFlareAPIKey)
	)

	if cloudflareEmail == "" {
		cloudflareEmail = c.CloudFlareEmail
	}

	if cloudflareAPIKey == "" {
		cloudflareAPIKey = c.CloudFlareKey
	}

	api, err := cloudflare.New(cloudflareAPIKey, cloudflareEmail)
	if err != nil {
		log.Println("cloudflare could not instantiate, failed with error ", err.Error())
		return err
	}

	zoneID := c.CloudFlareZoneID
	if c.CloudFlareZoneID == "" {
		zoneID, err = api.ZoneIDByName(c.CloudFlareZoneName)
		if err != nil {
			log.Println("could not fetch cloudflare zones")
			return err
		}
	}

	dnsResponses, err := api.DNSRecords(zoneID, cloudflare.DNSRecord{})
	if err != nil {
		log.Println("could not fetch dns records for zone: ", zoneID)
		return err
	}

	recordType := "A"
	if c.Cloud == AwsCloud {
		recordType = "CNAME"
	}

	for _, externalName := range c.ExternalHostNames {
		data := struct {
			Branch string
		}{
			Branch: c.circleBranch(),
		}

		t, err := template.New("dns-string").Parse(externalName)
		if err != nil {
			log.Println(err)
		}

		var tpl bytes.Buffer
		if err := t.Execute(&tpl, data); err != nil {
			return err
		}

		newDNSRecord := cloudflare.DNSRecord{
			Name:    tpl.String(),
			Type:    recordType,
			Content: loadbalancer,
		}
		for _, dnsRecord := range dnsResponses {
			if contains(c.ExternalHostNames, dnsRecord.Name) {
				err := api.UpdateDNSRecord(zoneID, dnsRecord.ID, newDNSRecord)
				if err != nil {
					log.Println("unable to update dns: ", dnsRecord.Name)
				}
			} else {
				createDNSResponse, err := api.CreateDNSRecord(zoneID, newDNSRecord)
				if err != nil {
					log.Println("cloudflare could not create the records, failed with error", err.Error())
					return err
				}
				if createDNSResponse.Success {
					log.Println("cloudflare successfully created DNS Record")
				} else {
					log.Println("cloudflare failed creating dns with internal error, failed with ", createDNSResponse.Errors)
				}
			}
		}
	}
	return nil
}

func (c *Config) HelmRunScript() {
	pod := c.runCmdOutput("bash", "-c", fmt.Sprintf("kubectl get pod -n %s --selector=app=%s -o jsonpath='{.items[0].metadata.name}'", c.circleBranch(), c.RunScript.PodAppLabel))

	for _, i := range c.RunScript.Cmds {
		c.runCmd("kubectl", "exec", "-i", pod, "-n", c.circleBranch(), "-c", c.RunScript.Container, "--", i)
	}
}
