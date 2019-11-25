package main

import (
	"os"
	"strings"
)

type Git struct {
	Branch string
	Sha    string
}

func (c *Git) DockerBranch() string {
	return strings.TrimSpace(strings.ToLower(runCmdOutput("bash", "-c", os.ExpandEnv("echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9]/-/g'"))))
}

func (c *Git) DockerSha1() string {
	return c.Sha
}

func (c *Git) GetDefaultBranch() string {
	return os.Getenv("CIRCLE_BRANCH")
}

func (c *Git) GetDefaultSha1() string {
	return os.Getenv("CIRCLE_SHA1")
}
