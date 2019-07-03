#!/bin/bash

set -e

source /scripts/set_env.sh
if [ "$CLOUD_PROVIDER" = "gcp" ]
then
    echo $GCLOUD_SERVICE_KEY > $HOME/gcloud-service-key.json
    gcloud auth activate-service-account --key-file=$HOME/gcloud-service-key.json
elif [ "$CLOUD_PROVIDER" = "aws" ]
then
    # Ensure that AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_DEFAULT_REGION are set
fi
