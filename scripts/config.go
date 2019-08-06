package deploytag

import (
	"os/exec"

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

func (c *Config) runCmd(cmdArgs ...string) {
	cmd := exec.Command(cmdArgs[0], cmdArgs[1:len(cmdArgs)-1]...)
	_, err := pty.Start(cmd)
	if err != nil {
		panic(err)
	}
}
