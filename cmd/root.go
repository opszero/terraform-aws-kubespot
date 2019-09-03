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
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"github.com/spf13/viper"
)

var (
	config = &Config{}
)

// rootCmd represents the base command when called without any subcommands
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

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	cobra.OnInitialize(initConfig)

	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.

	rootCmd.PersistentFlags().StringVar(&config.Cloud, "cloud", "", "aws, gcp, or azure")
	rootCmd.PersistentFlags().StringVar(&config.AWSAccessKeyID, "aws-access-key-id", os.Getenv("AWS_ACCESS_KEY_ID"), "AWS Access Key")
	rootCmd.PersistentFlags().StringVar(&config.AWSSecretAccessKey, "aws-secret-access-key", os.Getenv("AWS_SECRET_ACCESS_KEY"), "AWS Secret Access Key")
	rootCmd.PersistentFlags().StringVar(&config.AWSDefaultRegion, "aws-default-region", os.Getenv("AWS_DEFAULT_REGION"), "AWS Secret Access Key")
	rootCmd.PersistentFlags().StringVar(&config.GCPServiceKeyFile, "gcp-service-key-file", "", "GCP Auth File. ~/gcp.json")
	rootCmd.PersistentFlags().StringVar(&config.GCPServiceKeyBase64, "gcp-service-key-base64", "", "Base64 encoded version of gcp-service-key-base64")

	rootCmd.PersistentFlags().StringVar(&config.CloudAwsSecretId, "cloud-aws-secret-id", "", "Use AWS Secrets Manager for Config. If set it pull the environment variables from aws secrets manager.")
	buildCmd.Flags().StringArrayVar(&config.AppAwsSecretIds, "app-aws-secret-ids", []string{}, "Ex. 1234.dkr.ecr.us-west-2.amazonaws.com")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	viper.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		fmt.Println("Using config file:", viper.ConfigFileUsed())
	}
}
