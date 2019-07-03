#!/bin/bash

set -e

source /scripts/set_env.sh
if [ "$CLOUD_PROVIDER" = "gcp" ]
then
    echo $GCLOUD_SERVICE_KEY > $HOME/gcloud-service-key.json
    gcloud auth activate-service-account --key-file=$HOME/gcloud-service-key.json
elif [ "$CLOUD_PROVIDER" = "aws" ]
then
    #TODO
fi
