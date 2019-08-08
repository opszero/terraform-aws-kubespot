package cmd

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/secretsmanager"

	"github.com/a8m/envsubst"
	"github.com/joho/godotenv"
)

const (
	AwsCloud   = "aws"
	GcpCloud   = "gcp"
	AzureCloud = "azure"
)

type Config struct {
	Cloud              string
	AWSAccessKeyID     string
	AWSSecretAccessKey string
	AWSDefaultRegion   string

	GCPServiceKeyFile   string
	GCPServiceKeyBase64 string
	// GOOGLE_PROJECT_ID=alien-clover-238521 GOOGLE_COMPUTE_ZONE=us-central1 GOOGLE_CLUSTER_NAME=qa-us-central1

	AwsSecretId string

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
	}
}

func (c *Config) runCmd(cmdArgs ...string) {
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
		log.Fatalf("runCmd failed with %s\n", err)
	}
}

func (c *Config) getAwsSecretForCloud() {
	svc := secretsmanager.New(session.New())
	input := &secretsmanager.GetSecretValueInput{
		SecretId:     aws.String(c.AwsSecretId),
		VersionStage: aws.String("AWSCURRENT"), // VersionStage defaults to AWSCURRENT if unspecified
	}

	// In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
	// See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html

	result, err := svc.GetSecretValue(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case secretsmanager.ErrCodeDecryptionFailure:
				// Secrets Manager can't decrypt the protected secret text using the provided KMS key.
				fmt.Println(secretsmanager.ErrCodeDecryptionFailure, aerr.Error())

			case secretsmanager.ErrCodeInternalServiceError:
				// An error occurred on the server side.
				fmt.Println(secretsmanager.ErrCodeInternalServiceError, aerr.Error())

			case secretsmanager.ErrCodeInvalidParameterException:
				// You provided an invalid value for a parameter.
				fmt.Println(secretsmanager.ErrCodeInvalidParameterException, aerr.Error())

			case secretsmanager.ErrCodeInvalidRequestException:
				// You provided a parameter value that is not valid for the current state of the resource.
				fmt.Println(secretsmanager.ErrCodeInvalidRequestException, aerr.Error())

			case secretsmanager.ErrCodeResourceNotFoundException:
				// We can't find the resource that you asked for.
				fmt.Println(secretsmanager.ErrCodeResourceNotFoundException, aerr.Error())
			}
		} else {
			// Print the error, cast err to awserr.Error to get the Code and
			// Message from an error.
			fmt.Println(err.Error())
		}
		return
	}

	// Decrypts secret using the associated KMS CMK.
	// Depending on whether the secret is a string or binary, one of these fields will be populated.
	if result.SecretString == nil {
		return
	}

	c.EnvConfig, err = godotenv.Parse(strings.NewReader(*result.SecretString))
	if err != nil {
		log.Println(err)
	}

	for k := range c.EnvConfig {
		log.Println("Setting up var", k)
		os.Setenv(k, c.EnvConfig[k])
	}

}

func (c *Config) Init() {
	if c.AwsSecretId != "" {
		c.getAwsSecretForCloud()
	}

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
		//     export HELM_NAME="$HELM_NAME"
		//     export SUBDOMAIN=${SUBDOMAIN:-$HELM_NAME}
		//     export DOMAIN=${DOMAIN:-"opszero.com"}
		//     export HOST="$SUBDOMAIN.$DOMAIN"
		//     export URL_HOST="https://$HOST"
		//     export CIRCLE_BRANCH=$(echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9_]/-/g')

		//     export K8S_DEPLOY_ENV_SET=true

	}

}

func (c *Config) DockerNoImageExists() {
	// function no_image_exists(){
	// 	if [ "$CLOUD_PROVIDER" = "gcp" ]
	// 	then
	// 		[ $(gcloud container images list-tags --filter="tags=($DOCKER_TAG)" "${CONTAINER_REGISTRY}/${PROJECT_ID}/${BASE_IMAGE}" | wc -l) -eq 0 ]
	// 		return $?
	// 	elif [ "$CLOUD_PROVIDER" = "aws" ]
	// 	then
	// 		[ $(aws ecr describe-images --repository-name "${PROJECT_ID}/${BASE_IMAGE}" --image-ids="imageTag=$DOCKER_TAG" | grep imageDetails | wc -l) -eq 0 ]
	// 		return $?
	// 	else
	// 		return 1
	// 	fi

	// }
}

func (c *Config) DockerShouldBuildBase() {
	// TODO: Should check serveral different files to see if they changed.

	// function should_build_base(){
	// 	# If a Dockerfile.base exists
	// 	if [ -e "Dockerfile.base" ]
	// 	then
	// 		# Check if a base image doesn't exist yet.
	// 		if no_image_exists || [ -n "$FORCE_BASE_BUILD" ]
	// 		then
	// 			return 0
	// 		else
	// 			# Otherwise compare the Dockerfile.base with the latest sha
	// 			local BASE_COMMIT=$(git log -1 --format=format:%H --full-diff Dockerfile.base)
	// 			if [ "$BASE_COMMIT" = "$CIRCLE_SHA1" ]
	// 			then
	// 				return 0
	// 			else
	// 				return 1
	// 			fi
	// 		fi
	// 	else
	// 		return 1
	// 	fi
	// }
}

func (c *Config) DockerLogin() {
	log.Println("Docker Login")
	switch strings.ToLower(c.Cloud) {
	case GcpCloud:
		c.runCmd("bash", "-c", fmt.Sprintf("'gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://%s'", c.Docker.Build.ContainerRegistry))
	case AwsCloud:
		c.runCmd("aws", "ecr", "get-login", "--no-include-email")
	}
}

func (c *Config) DockerBaseCount() bool {
	switch strings.ToLower(c.Cloud) {
	case GcpCloud:
		c.runCmd("bash", "-c", "gcloud container images list-tags --filter=\"tags=($CIRCLE_BRANCH)\" --format=\"table[no-heading](digest)\" \"${CONTAINER_REGISTRY}/${PROJECT_ID}/${BASE_IMAGE}\" | wc -l")
	case AwsCloud:
		c.runCmd("bash", "-c", "aws ecr describe-images --repository-name \"${PROJECT_ID}/${BASE_IMAGE}\" --image-ids=\"imageTag=$CIRCLE_BRANCH\" | grep imageDetails | wc -l")
	}
}

func (c *Config) dockerCircleImageWithSuffix(suffix string) string {
	return fmt.Sprintf("%s/%s/%s:%s", c.Docker.Build.ContainerRegistry, c.Docker.Build.ProjectId, c.Docker.Build.Image, suffix)
}

func (c *Config) DockerBuildImage(image, dockerfile string) {
	var (
		shaImage = c.dockerCircleImageWithSuffix(os.Getenv("CIRCLE_SHA1"))
		// CIRCLE_BRANCH=$(echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9_]/-/g')
		branchImage = c.dockerCircleImageWithSuffix(os.Getenv("CIRCLE_BRANCH"))
		latestImage = c.dockerCircleImageWithSuffix("latest")
	)

	log.Println("Docker Build Image")

	// os.Getenv("DOCKER_BUILD_ARGS"),
	c.runCmd("docker", "build", "-t", image, "-f", dockerfile, ".")

	c.runCmd("docker", "tag", image, shaImage)
	c.runCmd("docker", "push", shaImage)

	c.runCmd("docker", "tag", image, branchImage)
	c.runCmd("docker", "push", branchImage)

	if os.Getenv("CIRCLE_BRANCH") == "master" {
		c.runCmd("docker", "tag", image, latestImage)
		c.runCmd("docker", "push", latestImage)
	}
}

func (c *Config) DockerBuild() {
	c.DockerLogin()

	// # If we've created a base image for this branch, let's use it. Otherwise use the latest base image.
	if false { //; base_count
		os.Setenv("DOCKER_TAG", "latest")
	} else {
		os.Setenv("DOCKER_TAG", os.Getenv("CIRCLE_BRANCH"))
	}

	os.Setenv("CONTAINER_REGISTRY", c.Docker.Build.ContainerRegistry)
	os.Setenv("PROJECT_ID", c.Docker.Build.ProjectId)

	if true { // should_build_base
		baseImage := fmt.Sprintf("%s_base", c.Docker.Build.Image)
		os.Setenv("BASE_IMAGE", baseImage)
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

	log.Println(string(subset))
	c.DockerBuildImage(c.Docker.Build.Image, "Dockerfile.sub")
}

func (c *Config) FrameworkRailsDbInit() {
	// #!/bin/bash

	// set -ex

	// # Wait until the connection is available or timeout after 10 seconds
	// timeout 10 /scripts/db_wait.sh

	// source /scripts/set_env.sh

	// echo "Rails Env is ${RAILS_ENV}"

	// if rake db:exists
	// then
	// 	rake db:migrate
	// else
	// 	# create a database using the deployer account and set the
	// 	# ownership to the service user
	// 	rake db:create
	// 	rake db:schema:load
	// 	#DATABASE_USER=deployer rake db:alter_owner
	// 	#DATABASE_USER=deployer rake db:add_extensions
	// 	rake db:migrate
	// 	rake db:seed
	// fi

}

func (c *Config) KubernetesApplyDockerRegistrySecrets() {
	// #!/bin/bash

	// set -e

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
	// #!/bin/bash

	// set -e

	// source /scripts/set_env.sh
	// if [ "$CLOUD_PROVIDER" = "gcp" ]
	// then
	// 	gcloud --quiet config set project ${GOOGLE_PROJECT_ID}
	// 	gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE}
	// 	gcloud --quiet container clusters get-credentials ${GOOGLE_CLUSTER_NAME}
	// elif [ "$CLOUD_PROVIDER" = "aws" ]
	// then
	// 	aws eks --region ${AWS_DEFAULT_REGION} update-kubeconfig --name ${AWS_CLUSTER_NAME}
	// fi
}

func (c *Config) KubernetesDeploy() {
	// #!/bin/bash

	// set -ex

	// /scripts/config_k8s.sh

	// source /scripts/set_env.sh

	// HELM_HOME=$(helm home)
	// mkdir -p $HELM_HOME

	// HELM_ARGS=()

	// CIRCLE_BRANCH=$(echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9]/-/g' | tr '[:upper:]' '[:lower:]')

	// if [ -n "$HELM_TLS" ]
	// then
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
	// fi

	// if [ "$CIRCLE_BRANCH" = "master" ] || [ "$CIRCLE_BRANCH" = "" ]
	// then
	// 	# use defaults for now
	// 	echo "deploying..."
	// else
	// 	HELM_ARGS+=(
	// 		--namespace $CIRCLE_BRANCH
	// 	)

	// 	if ! kubectl get namespaces | grep -q "$CIRCLE_BRANCH"
	// 	then
	// 		kubectl create namespace $CIRCLE_BRANCH
	// 	fi

	// 	/scripts/apply_registry_secret.sh
	// fi
	// TILLER_NAMESPACE=${TILLER_NAMESPACE:-"kube-system"}

	// HELM_ARGS+=(
	// 	--set ingress.hosts={$HOST}
	// 	--set ingress.tls[0].hosts={$HOST}
	// 	--set ingress.tls[0].secretName=$HELM_NAME-staging-cert
	// 	--set image.tag=${CIRCLE_SHA1}
	// 	--tiller-namespace=$TILLER_NAMESPACE
	// 	--force
	// 	--wait
	// 	--install
	// )

	// if [ -n "$HELM_VARS" ]
	// then
	// 	HELM_ARGS+=($(echo "$HELM_VARS" | envsubst))
	// fi

	// helm upgrade $HELM_NAME $CHART_NAME "${HELM_ARGS[@]}"

}

func (c *Config) DatabaseExists() {
	// 	package main

	// import (
	//   "database/sql"
	//   "fmt"

	//   _ "github.com/lib/pq"
	// )

	// const (
	//   host     = "localhost"
	//   port     = 5432
	//   user     = "postgres"
	//   password = "your-password"
	//   dbname   = "calhounio_demo"
	// )

	// func main() {
	//   psqlInfo := fmt.Sprintf("host=%s port=%d user=%s "+
	//     "password=%s dbname=%s sslmode=disable",
	//     host, port, user, password, dbname)
	//   db, err := sql.Open("postgres", psqlInfo)
	//   if err != nil {
	//     panic(err)
	//   }
	//   defer db.Close()

	//   err = db.Ping()
	//   if err != nil {
	//     panic(err)
	//   }

	//   fmt.Println("Successfully connected!")
	// }
}

func (c *Config) DatabaseWait() {
	// #!/bin/bash

	// set -e

	// while ! nc -z localhost $DATABASE_PORT; do
	//   sleep 0.1 # wait for 1/10 of the second before check again
	// done
}
func (c *Config) DatabaseConnect() {
	// 	#!/bin/bash

	// ERROR_STATUS=0
	// set -e

	// function log_execute() {
	//     set -x
	//     "$@"
	//     { set +x; } 2>/dev/null
	// }

	// # authenticate with gcp
	// /scripts/auth.sh
	// # configure kubernetes
	// /scripts/config_k8s.sh

	// kubectl port-forward "$DATABASE_DEPLOYMENT" $DATABASE_PORT:$DATABASE_FORWARD_PORT -n default &

	// # Wait until the connection is available or timeout after 10 seconds
	// timeout 10 /scripts/db_wait.sh

	// PORT_FORWARD_PID=$!

	// sleep 2
	// log_execute "$@" || ERROR_STATUS=$?

	// kill $PORT_FORWARD_PID

	// exit $ERROR_STATUS

}

func (c *Config) SecretEnvSubst() {
	// 	require "yaml"
	// class App < Thor
	//   package_name "App"
	//   desc "config_yaml FILE", "generate a yaml config for a given environment"
	//   method_option :env, aliases: "-e", desc: "The environment that you care about"
	//   def config_yaml(file)
	//     if options[:env]
	//       puts YAML.dump(
	//              YAML.load(
	//                YAML.load(`cat #{file} | envsubst`.to_yaml)
	//              )[options[:env]]
	//            )
	//     else
	//       puts File.read(file)
	//     end
	//   end
	// end

}
