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
