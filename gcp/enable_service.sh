#!/bin/bash

if [ $# -lt 1 ]
then
  echo "Usage: enable required service for auditube, only argument should be the project id"
fi
echo "enabling services for project $1"
gcloud services enable servicenetworking.googleapis.com --project "$1"
gcloud services enable container.googleapis.com --project "$1"
gcloud services enable compute.googleapis.com --project "$1"
gcloud services enable sqladmin.googleapis.com --project "$1"
gcloud services enable cloudresourcemanager.googleapis.com --project "$1"