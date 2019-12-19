#!/bin/bash

set -x

export KUBECONFIG=$1

helm repo add stable https://kubernetes-charts.storage.googleapis.com/

# https://github.com/helm/charts/tree/master/stable/nginx-ingress
# https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/configmap.md

helm upgrade --install ingress stable/nginx-ingress -f ./values.yaml
