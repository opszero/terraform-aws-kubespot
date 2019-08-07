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

func (c *Config) SetEnv() {
	// 	#!/bin/bash

	// set -e

	// if [ -z "$K8S_DEPLOY_ENV_SET" ]
	// then
	//     if [ -z "$DATABASE" ]
	//     then
	//         if [ "$CIRCLE_BRANCH" = "master" ] || [ "$CIRCLE_BRANCH" = "" ]
	//         then
	//             DATABASE="$CIRCLE_PROJECT_REPONAME-staging"
	//         else
	//             DATABASE="$CIRCLE_PROJECT_REPONAME-$CIRCLE_BRANCH"
	//         fi
	//         DATABASE=$(echo "$DATABASE" | sed 's/[^A-Za-z0-9]/-/g')
	//     fi

	//     export DATABASE="$DATABASE"
	//     if [ "$CIRCLE_BRANCH" = "master" ] || [ "$CIRCLE_BRANCH" = "" ]
	//     then
	//         # set staging related data
	//         echo "configuring staging env"
	//     else
	//         # set feature deployment data
	//         echo "configuring feature deployment env"
	//         HELM_NAME=$(echo $CIRCLE_BRANCH-$CHART_NAME | sed 's/[^A-Za-z0-9]/-/g' | tr '[:upper:]' '[:lower:]')
	//     fi

	//     export CLOUD_PROVIDER=${CLOUD_PROVIDER:-"aws"}
	//     export HELM_NAME="$HELM_NAME"
	//     export SUBDOMAIN=${SUBDOMAIN:-$HELM_NAME}
	//     export DOMAIN=${DOMAIN:-"opszero.com"}
	//     export HOST="$SUBDOMAIN.$DOMAIN"
	//     export URL_HOST="https://$HOST"
	//     export PROJECT_ID=${PROJECT_ID:-"opszero"}
	//     export CIRCLE_BRANCH=$(echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9_]/-/g')
	//     export CONTAINER_REGISTRY=${CONTAINER_REGISTRY:-"1234.dkr.ecr.us-west-2.amazonaws.com"}
	//     export BASE_IMAGE=${IMAGE}_base

	//     if [ -n "$AWS_SECRETS" ] && [ -e /scripts/aws_secrets.rb ]
	//     then
	//         AWS_SECRETS_FILE=/tmp/.env.aws
	//         ruby /scripts/aws_secrets.rb > $AWS_SECRETS_FILE
	//         # clear out any env that should be overridden by the secrets manager
	//         # export AWS_ACCESS_KEY_ID=
	//         # export AWS_SECRET_ACCESS_KEY=
	//         # allow the apps to reset any extra variables
	//         if [ -e ./scripts/reset_env_vars.sh ]
	//         then
	//             source ./scripts/reset_env_vars.sh
	//         fi
	//         source $AWS_SECRETS_FILE
	//     fi
	//     export K8S_DEPLOY_ENV_SET=true
	// fi

}

func (c *Config) CloudAuth() {
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
	// function should_build_base(){
	// 	# If a Dockerfile.base exists
	// 	if [ -e "Dockerfile.base" ]
	// 	then
	// 		# Check if a base image doesn't exist yet.
	// 		if no_image_exists || [ -n "$FORCE_BASE_BUILD" ]
	// 		then
	// 			return 0
	// 		# Check if there's a custom script to build the base image
	// 		elif [ -e "./scripts/should_build_base.sh" ]
	// 		then
	// 			./scripts/should_build_base.sh
	// 			return $?
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

func (c *Config) DockerBuildImage() {
	// function build_image(){
	// 	local IMAGE=$1
	// 	local DOCKER_FILE=$2

	// 	docker build ${DOCKER_BUILD_ARGS} -t ${IMAGE} -f $DOCKER_FILE .

	// 	docker tag ${IMAGE} ${CONTAINER_REGISTRY}/${PROJECT_ID}/${IMAGE}:${CIRCLE_SHA1}
	// 	docker push ${CONTAINER_REGISTRY}/${PROJECT_ID}/${IMAGE}:${CIRCLE_SHA1}

	// 	docker tag ${IMAGE} ${CONTAINER_REGISTRY}/${PROJECT_ID}/${IMAGE}:${CIRCLE_BRANCH}
	// 	docker push ${CONTAINER_REGISTRY}/${PROJECT_ID}/${IMAGE}:${CIRCLE_BRANCH}

	// 	if [ "$CIRCLE_BRANCH" = "master" ]
	// 	then
	// 		docker tag ${IMAGE} ${CONTAINER_REGISTRY}/${PROJECT_ID}/${IMAGE}:latest
	// 		docker push ${CONTAINER_REGISTRY}/${PROJECT_ID}/${IMAGE}:latest
	// 	fi
	// }
}

func (c *Config) DockerLogin() {
	// function docker_login(){
	// 	if [ "$CLOUD_PROVIDER" = "gcp" ]
	// 	then
	// 		# Auth with GCLOUD
	// 		gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://${CONTAINER_REGISTRY}
	// 	elif [ "$CLOUD_PROVIDER" = "aws" ]
	// 	then
	// 		eval $(aws ecr get-login --no-include-email)
	// 	fi
	// }
}

func (c *Config) DockerBaseCount() {
	// function base_count(){
	// 	if [ "$CLOUD_PROVIDER" = "gcp" ]
	// 	then
	// 		return $(gcloud container images list-tags --filter="tags=($CIRCLE_BRANCH)" --format="table[no-heading](digest)" "${CONTAINER_REGISTRY}/${PROJECT_ID}/${BASE_IMAGE}" | wc -l)
	// 	elif [ "$CLOUD_PROVIDER" = "aws" ]
	// 	then
	// 		return $(aws ecr describe-images --repository-name "${PROJECT_ID}/${BASE_IMAGE}" --image-ids="imageTag=$CIRCLE_BRANCH" | grep imageDetails | wc -l)
	// 	fi
	// }
}

func (c *Config) DockerBuild() {

	// docker_login

	// # If we've created a base image for this branch, let's use it. Otherwise use the latest base image.
	// if base_count
	// then
	//     export DOCKER_TAG="latest"
	// else
	//     export DOCKER_TAG=$CIRCLE_BRANCH
	// fi

	// if should_build_base
	// then
	//     build_image $BASE_IMAGE Dockerfile.base
	// fi

	// cat Dockerfile | envsubst > Dockerfile.sub

	// build_image $IMAGE Dockerfile.sub
}
