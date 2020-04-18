package main

import (
	"bytes"
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"text/template"

	"github.com/cloudflare/cloudflare-go"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/secretsmanager"

	"github.com/a8m/envsubst"
)

const (
	CloudflareEmail  = "CLOUDFLARE_EMAIL"
	CloudflareAPIKey = "CLOUDFLARE_APIKEY"
	CloudflareDomain = "CLOUDFLARE_DOMAIN"
	CloudflareZoneID = "CLOUDFLARE_ZONE_ID"
)

type Config struct {
	AWSAccessKeyID     string
	AWSSecretAccessKey string
	AWSRegion          string

	AppAwsSecretIds []string
	AppEnvConfig    string

	Git Git

	Docker struct {
		Tag string
	}

	Cloudflare struct {
		Key               string
		ZoneName          string
		ZoneID            string
		ExternalHostNames []string
	}

	Build struct {
		DotEnvFile string

		ContainerRegistry string
		ProjectId         string
		Image             string
	}

	Deploy struct {
		ChartName   string
		HelmSet     []string
		ClusterName string
	}
}

func (c *Config) loadAppAwsSecrets() {
	sess, err := session.NewSession(&aws.Config{
		Credentials: credentials.NewStaticCredentials(c.AWSAccessKeyID, c.AWSSecretAccessKey, ""),
		Region:      aws.String(c.AWSRegion),
	})

	if err != nil {
		log.Fatal(err)
	}

	svc := secretsmanager.New(sess)

	fileContent := fmt.Sprintf("DEPLOYTAG_BRANCH=%s\n\n", c.Git.DockerBranch())
	for _, secretId := range c.AppAwsSecretIds {
		result, err := svc.GetSecretValue(&secretsmanager.GetSecretValueInput{
			SecretId: aws.String(secretId),
		})
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
	if c.AWSAccessKeyID == "" || c.AWSSecretAccessKey == "" || c.AWSRegion == "" {
		log.Println("Ensure that AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION are set!")
	} else {
		log.Println("AWS Configured")
	}

	c.loadAppAwsSecrets()

	os.Setenv("CONTAINER_REGISTRY", c.Build.ContainerRegistry)
	os.Setenv("PROJECT_ID", c.Build.ProjectId)

	if c.Git.DockerBranch() == "master" {
		log.Println("configuring production env")
		c.Docker.Tag = "latest"
	} else {
		log.Println("configuring staging env")
		c.Docker.Tag = c.Git.DockerBranch()
	}

	c.DockerLogin()

	log.Println("Circle Branch", c.Git.DockerBranch())
}

func (c *Config) DockerLogin() {
	log.Println("Docker Login")
	runCmd("bash", "-c", runCmdOutput("aws", "ecr", "get-login", "--no-include-email"))
}

func (c *Config) KuberneteConfig() {
	runCmd("aws", "eks", "--region", os.Getenv("AWS_REGION"), "update-kubeconfig", "--name", c.Deploy.ClusterName)
}

func (c *Config) dockerCircleImageWithSuffix(image, suffix string) string {
	return strings.TrimSpace(fmt.Sprintf("%s/%s/%s:%s", c.Build.ContainerRegistry, c.Build.ProjectId, image, suffix))
}

func (c *Config) dockerCircleImage(image string) string {
	return strings.TrimSpace(fmt.Sprintf("%s/%s/%s", c.Build.ContainerRegistry, c.Build.ProjectId, image))
}

func (c *Config) DockerBuildImage(image, dockerfile string) {
	var (
		shaImage    = c.dockerCircleImageWithSuffix(image, c.Git.DockerSha1())
		branchImage = c.dockerCircleImageWithSuffix(image, c.Git.DockerBranch())
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
	err := runCmd(buildCmd...)
	if err != nil {
		log.Fatal("Couldn't build image")
	}

	runCmd("docker", "tag", image, shaImage)
	runCmd("docker", "push", shaImage)

	runCmd("docker", "tag", image, branchImage)
	runCmd("docker", "push", branchImage)

	if c.Git.DockerBranch() == "master" {
		runCmd("docker", "tag", image, latestImage)
		runCmd("docker", "push", latestImage)
	}
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
	c.KuberneteConfig()

	os.Setenv("HELM_HOME", runCmdOutput("helm", "home"))
	os.MkdirAll(os.Getenv("HELM_HOME"), os.ModePerm)

	var helmArgs []string

	if c.Git.DockerBranch() == "master" || c.Git.DockerBranch() == "" {
		log.Println("Deploying")
	} else {
		helmArgs = append(helmArgs, "--namespace", c.Git.DockerBranch())
		runCmd("kubectl", "create", "namespace", c.Git.DockerBranch())
	}

	if os.Getenv("TILLER_NAMESPACE") == "" {
		os.Setenv("TILLER_NAMESPACE", "kube-system")
	}

	helmArgs = append(helmArgs,
		"--set", fmt.Sprintf("image.tag=%s", c.Git.DockerSha1()),
		"--set", fmt.Sprintf("deploytag.tag=%s", c.Docker.Tag),
		"--set", fmt.Sprintf("deploytag.cloud=AWS"),
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

	runCmd(append([]string{"helm", "upgrade", c.Git.DockerBranch(), c.Deploy.ChartName}, helmArgs...)...)
}

func dnsGet(records []cloudflare.DNSRecord, dnsName string) (string, bool) {
	for _, a := range records {
		if a.Name == dnsName {
			return a.ID, true
		}
	}
	return "", false
}

// Documentation for record types are found here https://api.cloudflare.com/#dns-records-for-a-zone-create-dns-record
// this will error out if the api is configured incorrectly, cannot fetch DNS records of zone or the zones themselves, or if
// it cannot create a DNS record (note: not update a record)
func (c *Config) DnsDeploy() error {
	c.Cloudflare.Key = os.Getenv(CloudflareAPIKey)
	c.Cloudflare.ZoneName = os.Getenv(CloudflareDomain)
	c.Cloudflare.ZoneID = os.Getenv(CloudflareZoneID)

	log.Println(c.Cloudflare)

	var (
		// TODO should exec from output or use something like this https://github.com/kubernetes/client-go/blob/master/examples/out-of-cluster-client-configuration/main.go#L74
		loadbalancer = runCmdOutput("kubectl", "get", "svc", "ingress-nginx-ingress-controller", "-o", `jsonpath='{.status.loadBalancer.ingress[0].hostname}'`)
	)

	log.Println("LoadBalancer", loadbalancer)

	// XXX: Temporary fix for issue getting strings
	lb := []rune(loadbalancer)
	loadbalancer = string(lb[1 : len(lb)-1])

	log.Println("LoadBalancer", loadbalancer)

	api, err := cloudflare.NewWithAPIToken(c.Cloudflare.Key)
	if err != nil {
		log.Println(err)
		return err
	}

	zoneID := c.Cloudflare.ZoneID
	if c.Cloudflare.ZoneName != "" {
		zoneID, err = api.ZoneIDByName(c.Cloudflare.ZoneName)
		if err != nil {
			log.Println(err)
			return err
		}
	}

	dnsResponses, err := api.DNSRecords(zoneID, cloudflare.DNSRecord{})
	if err != nil {
		log.Println(err)
		return err
	}

	recordType := "CNAME"

	for _, externalName := range c.Cloudflare.ExternalHostNames {
		data := struct {
			Branch string
		}{
			Branch: c.Git.DockerBranch(),
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
			Proxied: true,
		}

		log.Println("DNS", newDNSRecord)
		log.Println("externalname", externalName)

		dnsId, ok := dnsGet(dnsResponses, newDNSRecord.Name)
		if ok {
			log.Println("Exists", dnsId)
			err := api.UpdateDNSRecord(zoneID, dnsId, newDNSRecord)
			if err != nil {
				log.Println(err)
				return err

			}
		} else {
			log.Println("New DNS")
			createDNSResponse, err := api.CreateDNSRecord(zoneID, newDNSRecord)
			if err != nil {
				log.Println(err)
				return err
			}
			if createDNSResponse.Success {
				log.Println("cloudflare successfully created DNS Record")
			} else {
				log.Println("cloudflare failed creating dns with internal error, failed with ", createDNSResponse.Errors)
			}
		}
	}
	return nil
}
