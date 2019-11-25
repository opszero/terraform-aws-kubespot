package main

import (
	"fmt"
	"log"
	"os"

	"github.com/spf13/cobra"
)

var (
	config = &Config{}
)

func main() {
	var rootCmd = &cobra.Command{
		Use:   "deploytag",
		Short: "CI /CD Helper for Kubernetes and Serverless Apps",
		Long: `A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
		// Uncomment the following line if your bare application
		// has an action associated with it:
		//	Run: func(cmd *cobra.Command, args []string) { },
	}

	rootCmd.PersistentFlags().StringVar(&config.Cloud, "cloud", "", "aws, gcp, or azure")
	rootCmd.PersistentFlags().StringVar(&config.AWSAccessKeyID, "aws-access-key-id", os.Getenv("AWS_ACCESS_KEY_ID"), "AWS Access Key")
	rootCmd.PersistentFlags().StringVar(&config.AWSSecretAccessKey, "aws-secret-access-key", os.Getenv("AWS_SECRET_ACCESS_KEY"), "AWS Secret Access Key")
	rootCmd.PersistentFlags().StringVar(&config.AWSRegion, "aws-region", os.Getenv("AWS_REGION"), "AWS Secret Access Key")

	rootCmd.PersistentFlags().StringVar(&config.CloudAwsSecretId, "cloud-aws-secret-id", "", "Use AWS Secrets Manager for Config. If set it pull the environment variables from aws secrets manager.")
	rootCmd.PersistentFlags().StringArrayVar(&config.AppAwsSecretIds, "app-aws-secret-ids", []string{}, "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com")

	rootCmd.PersistentFlags().StringVar(&config.Git.Branch, "branch", config.Git.GetDefaultBranch(), "The Git Branch to Tag the Docker Image")
	rootCmd.PersistentFlags().StringVar(&config.Git.Sha, "sha", config.Git.GetDefaultSha1(), "The Git Sha to Tag the Docker Image")

	var runScriptCmd = &cobra.Command{
		Use:   "run-script",
		Short: "A brief description of your command",
		Long: `A longer description that spans multiple lines and likely contains examples
	and usage of using your command. For example:
	
	Cobra is a CLI library for Go that empowers applications.
	This application is a tool to generate the needed files
	to quickly create a Cobra application.`,
		Run: func(cmd *cobra.Command, args []string) {
			config.Init()
			config.HelmRunScript()
		},
	}

	runScriptCmd.Flags().StringVar(&config.RunScript.PodAppLabel, "pod-app-label", "", "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com ")
	runScriptCmd.Flags().StringVar(&config.RunScript.Container, "container", "", "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com ")
	runScriptCmd.Flags().StringArrayVar(&config.RunScript.Cmds, "cmds", []string{}, "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com ")

	rootCmd.AddCommand(runScriptCmd)

	// deployCmd represents the deploy command
	var deployCmd = &cobra.Command{
		Use:   "deploy",
		Short: "A brief description of your command",
		Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
		Run: func(cmd *cobra.Command, args []string) {
			config.Init()
			config.HelmDeploy()
		},
	}

	rootCmd.AddCommand(deployCmd)

	deployCmd.Flags().StringVar(&config.Deploy.ChartName, "chart-name", "", "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com ")
	deployCmd.Flags().StringArrayVar(&config.Deploy.HelmSet, "helm-set", []string{}, "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com ")

	deployCmd.Flags().StringVar(&config.Build.ContainerRegistry, "container-registry", "", "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com ")
	deployCmd.Flags().StringVar(&config.Build.ProjectId, "project-id", "", "Ex. opszero")
	deployCmd.Flags().StringVar(&config.Build.Image, "image", "", "Ex. deploytag")

	var buildCmd = &cobra.Command{
		Use:   "build",
		Short: "A brief description of your command",
		Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
		Run: func(cmd *cobra.Command, args []string) {
			config.Init()
			config.DockerBuild()
		},
	}

	rootCmd.AddCommand(buildCmd)

	buildCmd.Flags().StringVar(&config.Build.DotEnvFile, "dotenv-file", "", "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com")
	buildCmd.Flags().StringVar(&config.Build.ContainerRegistry, "container-registry", "", "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com ")
	buildCmd.Flags().StringVar(&config.Build.ProjectId, "project-id", "", "Ex. opszero")
	buildCmd.Flags().StringVar(&config.Build.Image, "image", "", "Ex. deploytag")

	var dnsCmd = &cobra.Command{
		Use:   "dns",
		Short: "A brief description of your command",
		Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
		Run: func(cmd *cobra.Command, args []string) {
			config.Init()
			config.DnsDeploy()
		},
	}

	rootCmd.AddCommand(dnsCmd)

	dnsCmd.Flags().StringVar(&config.Cloudflare.Key, "cloudflare-key", os.Getenv(CloudflareAPIKey), "api key for cloudflare")
	dnsCmd.Flags().StringVar(&config.Cloudflare.ZoneName, "cloudflare-domain", os.Getenv(CloudflareDomain), "domain for cloudflare")
	dnsCmd.Flags().StringVar(&config.Cloudflare.ZoneID, "cloudflare-zone-id", os.Getenv(CloudflareZoneID), "domain for cloudflare")
	dnsCmd.Flags().StringArrayVar(&config.Cloudflare.ExternalHostNames, "record", []string{}, "list of external hostnames to resolve against the cluster's load balancer")

	log.SetFlags(log.LstdFlags | log.Lshortfile)

	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
