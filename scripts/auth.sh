#!/bin/bash

set -e

# Check if set_env exists and source it if it does
if [ -e ./scripts/set_env.sh ]
then
    source ./scripts/set_env.sh
elif [ -e /scripts/set_env.sh ]
then
    source /scripts/set_env.sh
fi

if [ "$CLOUD_PROVIDER" = "gcp" ]
then
    if [ -n "$GCLOUD_SERVICE_KEY"]
    then
        echo $GCLOUD_SERVICE_KEY > $HOME/gcloud-service-key.json
    elif [ -n "$GCLOUD_SERVICE_KEY_BASE64" ]
    then
        echo $GCLOUD_SERVICE_KEY_BASE64 | base64 -d > $HOME/gcloud-service-key.json
    else
        echo "No Google Service Account Key given"
    fi
    gcloud auth activate-service-account --key-file=$HOME/gcloud-service-key.json
elif [ "$CLOUD_PROVIDER" = "aws" ]
then
    if [ -z "AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_DEFAULT_REGION" ]
    then
        echo "Ensure that AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_DEFAULT_REGION are set"
        exit 1
    else
        echo "AWS configured"
    fi
fi
