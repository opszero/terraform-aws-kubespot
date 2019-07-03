#!/bin/bash

set -e

source /scripts/set_env.sh
if [ "$CLOUD_PROVIDER" = "gcp" ]
then
    gcloud --quiet config set project ${GOOGLE_PROJECT_ID}
    gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE}
    gcloud --quiet container clusters get-credentials ${GOOGLE_CLUSTER_NAME}
elif [ "$CLOUD_PROVIDER" = "aws" ]
then
        #TODO
fi


# TODO aws kubeconfig
