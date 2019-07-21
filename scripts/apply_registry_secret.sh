#!/bin/bash

set -e

if [ "$CLOUD_PROVIDER" = "gcp" ]
then
    kubectl get secret gcrsecret --export -o yaml | kubectl apply -n $CIRCLE_BRANCH -f -
    kubectl patch serviceaccount default -n $CIRCLE_BRANCH -p '{"imagePullSecrets": [{"name": "gcrsecret"}]}'
elif [ "$CLOUD_PROVIDER" = "aws" ]
then
    # kubectl get secret ecrsecret --export -o yaml | kubectl apply -n $CIRCLE_BRANCH -f -
    # kubectl patch serviceaccount default -n $CIRCLE_BRANCH -p '{"imagePullSecrets": [{"name": "ecrsecret"}]}'
    echo "EKS has native support to pull from ECR"
fi
