#!/bin/bash

set -e

if [ -z "$K8S_DEPLOY_ENV_SET" ]
then
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

    if [ -n "$AWS_SECRETS" ] && [ -e /scripts/aws_secrets.rb ]
    then
        AWS_SECRETS_FILE=/tmp/.env.aws
        ruby /scripts/aws_secrets.rb > $AWS_SECRETS_FILE
        # clear out any env that should be overridden by the secrets manager
        # export AWS_ACCESS_KEY_ID=
        # export AWS_SECRET_ACCESS_KEY=
        # allow the apps to reset any extra variables
        if [ -e ./scripts/reset_env_vars.sh ]
        then
            source ./scripts/reset_env_vars.sh
        fi
        source $AWS_SECRETS_FILE
    fi
    export K8S_DEPLOY_ENV_SET=true
fi
