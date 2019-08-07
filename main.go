package main

import "github.com/opszero/deploytag/cmd"

func main() {
	cmd.Execute()

	// Base Flags: --cloud [aws|gcp|azure] --aws-access-key-id --aws-secret-access-key --gcp-auth-file
	// set-env
	// database test
	// database wait
	// k8s configure
	// secret --aws-secret-manager [key] [key] [key]
	//    - https://godoc.org/github.com/joho/godotenv#Read
	// configmap --aws-secret-manager [key] [key] [key]
	//    - https://godoc.org/github.com/joho/godotenv#Read
	// framework rails
	// framework rails bundle
	// deploy
	// docker build
	// docker deps --base-image=debian
}
