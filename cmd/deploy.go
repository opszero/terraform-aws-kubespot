/*
Copyright © 2019 NAME HERE <EMAIL ADDRESS>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package cmd

import (
	"github.com/spf13/cobra"
)

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
		config.Deploy()
		// config.DeployDns()
	},
}

func init() {
	rootCmd.AddCommand(deployCmd)

	deployCmd.Flags().StringArrayVar(&config.Docker.Deploy.AwsSecretsIds, "aws-secret-ids", []string{}, "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com")
	deployCmd.Flags().StringVar(&config.Docker.Deploy.Env, "env", "", "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com ")
	deployCmd.Flags().StringVar(&config.Docker.Deploy.ChartName, "chart-name", "", "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com ")
	deployCmd.Flags().StringVar(&config.Docker.Deploy.HelmConfig, "helm-config", "", "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com ")
	deployCmd.Flags().StringArrayVar(&config.Docker.Deploy.HelmSet, "helm-set", []string{}, "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com ")

	deployCmd.Flags().StringVar(&config.Docker.Build.ContainerRegistry, "container-registry", "", "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com ")
	deployCmd.Flags().StringVar(&config.Docker.Build.ProjectId, "project-id", "", "Ex. opszero")
	deployCmd.Flags().StringVar(&config.Docker.Build.Image, "image", "", "Ex. deploytag")
}
