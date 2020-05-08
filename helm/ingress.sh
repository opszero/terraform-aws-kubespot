#!/bin/bash

set -x

export KUBECONFIG=$1

helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm upgrade --install ingress stable/nginx-ingress -f ./values.yml
