#!/bin/bash

set -x

export KUBECONFIG=$1

kubectl --namespace kube-system create sa tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

helm init --service-account tiller --wait --upgrade
helm repo update

# https://github.com/helm/charts/tree/master/stable/nginx-ingress
# https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/configmap.md
helm upgrade --install ingress stable/nginx-ingress --set controller.config.enable-underscores-in-headers='"true"',controller.config.use-forwarded-headers='"true"'
