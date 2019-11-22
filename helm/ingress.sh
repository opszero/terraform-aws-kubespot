#!/bin/bash

set -x

export KUBECONFIG=$1

helm init
helm repo add nginx https://helm.nginx.com/stable

# https://github.com/helm/charts/tree/master/stable/nginx-ingress
# https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/configmap.md

helm install ingress-controller nginx/nginx-ingress --set controller.config.enable-underscores-in-headers='"true"',controller.config.use-forwarded-headers='"true"'
