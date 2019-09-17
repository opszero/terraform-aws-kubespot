#!/bin/bash

set -x

export KUBECONFIG=$1

kubectl --namespace kube-system create sa tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

helm init --service-account tiller --wait --upgrade
helm repo update

helm install stable/nginx-ingress --name ingress-nginx
