#!/bin/bash

set -e

if [ -z "$DATABASE" ]
then
    if [ "$CIRCLE_BRANCH" = "master" ] || [ "$CIRCLE_BRANCH" = "" ]
    then
        DATABASE="$CIRCLE_PROJECT_REPONAME-staging"
    else
        DATABASE="$CIRCLE_PROJECT_REPONAME-$CIRCLE_BRANCH"
    fi
    DATABASE=$(echo "$DATABASE" | sed 's/[^A-Za-z0-9]/-/g')
fi

export DATABASE="$DATABASE"
if [ "$CIRCLE_BRANCH" = "master" ] || [ "$CIRCLE_BRANCH" = "" ]
then
    # set staging related data
    echo "configuring staging env"
else
    # set feature deployment data
    echo "configuring feature deployment env"
    HELM_NAME=$(echo $CIRCLE_BRANCH-$CHART_NAME | sed 's/[^A-Za-z0-9]/-/g' | tr '[:upper:]' '[:lower:]')
fi

export CLOUD_PROVIDER=${CLOUD_PROVIDER:-"aws"}
export HELM_NAME="$HELM_NAME"
export SUBDOMAIN=${SUBDOMAIN:-$HELM_NAME}
export DOMAIN=${DOMAIN:-"tractionguest.com"}
export HOST="$SUBDOMAIN.$DOMAIN"
export URL_HOST="https://$HOST"
export PROJECT_ID=${PROJECT_ID:-"tractionguest"}
export CIRCLE_BRANCH=$(echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9_]/-/g')
export CONTAINER_REGISTRY=${CONTAINER_REGISTRY:-"291031131640.dkr.ecr.us-west-2.amazonaws.com"}
export BASE_IMAGE=${IMAGE}_base

if [ -n "$AWS_SECRETS" ]
then
   AWS_SECRETS_FILE=/tmp/.env.aws
   CURRENT_ENV_FILE=/tmp/.env.current
   env > $CURRENT_ENV_FILE
   aws secretsmanager get-secret-value --secret-id "$AWS_SECRETS" | jq -r '.SecretString' > $AWS_SECRETS_FILE
   source $AWS_SECRETS_FILE
   # don't overwrite already set variables
   source $CURRENT_ENV_FILE
fi
