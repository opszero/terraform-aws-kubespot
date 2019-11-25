#!/bin/bash

set -x

export KUBECONFIG=$1

helm init
# https://github.com/helm/charts/tree/master/stable/nginx-ingress
# https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/configmap.md

helm upgrade --install ingress-controller stable/nginx-ingress --set controller.config.enable-underscores-in-headers='"true"',controller.config.use-forwarded-headers='"true"'
