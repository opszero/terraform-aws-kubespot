package cmd

import (
	"fmt"
	"log"
	"os"
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

	}
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

func (c *Config) DockerShouldBuildBase() {
	// 	#!/bin/bash

	// set -e

	// DEPENDENCIES_SHA1=$(git log -1 --format=format:%H --full-diff ./scripts/dependencies.sh)

	// if [ $DEPENDENCIES_SHA1 = $CIRCLE_SHA1 ]
	// then
	//     exit 0
	// else
	//     exit 1
	// fi
}

/*
Obsolete?

#!/bin/bash

set -e

PROJECT_ID=${PROJECT_ID:-"opszero/deploytag"}
DOCKER_FILE=${DOCKER_FILE:-"Dockerfile"}
CONTAINER_REGISTRY=${CONTAINER_REGISTRY:-"1234.dkr.ecr.us-west-2.amazonaws.com"}

set -x
docker build ${DOCKER_BUILD_ARGS} -t ${IMAGE} -f $DOCKER_FILE .

docker tag ${IMAGE} $CONTAINER_REGISTRY/${PROJECT_ID}/${IMAGE}:${CIRCLE_SHA1}
docker push $CONTAINER_REGISTRY/${PROJECT_ID}/${IMAGE}:${CIRCLE_SHA1}

CIRCLE_BRANCH=$(echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9_]/-/g')
docker tag ${IMAGE} $CONTAINER_REGISTRY/${PROJECT_ID}/${IMAGE}:${CIRCLE_BRANCH}
docker push $CONTAINER_REGISTRY/${PROJECT_ID}/${IMAGE}:${CIRCLE_BRANCH}

if [ "$CIRCLE_BRANCH" = "master" ]
then
    docker tag ${IMAGE} $CONTAINER_REGISTRY/${PROJECT_ID}/${IMAGE}:latest
    docker push $CONTAINER_REGISTRY/${PROJECT_ID}/${IMAGE}:latest
fi
*/
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

func (c *Config) FrameworkRailsBundle() {
	// gem install bundler -v "$(cat Gemfile.lock | grep -A 1 "BUNDLED WITH" | grep -v BUNDLED | awk '{print $1}')"

	// bundle config github.com $GITHUB_TOKEN:x-oauth-basic

	// if bundle check
	// then
	//     echo ""
	// else
	//     if [ "$RAILS_ENV" = "development" ] || [ "$RAILS_ENV" = "test" ] || [ "$RAILS_ENV" = "" ]
	//     then
	//         bundle install
	//     else
	//         bundle config --global frozen 1
	//         bundle install --without development test
	//     fi
	// fi

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
