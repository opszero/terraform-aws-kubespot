package cmd

import (
	"fmt"
	"log"
	"os/exec"
	"strings"

	"github.com/creack/pty"
)

const (
	AwsCloud   = "aws"
	GcpCloud   = "gcp"
	AzureCloud = "azure"
)

type Config struct {
	Cloud               string
	AWSAccessKeyID      string
	AWSSecretAccessKey  string
	AWSDefaultRegion    string
	GCPServiceKeyFile   string
	GCPServiceKeyBase64 string
}

func (c *Config) Init() {
	// # Check if set_env exists and source it if it does
	// if [ -e ./scripts/set_env.sh ]
	// then
	//     source ./scripts/set_env.sh
	// elif [ -e /scripts/set_env.sh ]
	// then
	//     source /scripts/set_env.sh
	// fi
}

func (c *Config) Auth() {
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
}

func (c *Config) runCmd(cmdArgs ...string) {
	cmd := exec.Command(cmdArgs[0], cmdArgs[1:len(cmdArgs)-1]...)
	_, err := pty.Start(cmd)
	if err != nil {
		panic(err)
	}
}
