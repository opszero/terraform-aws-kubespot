#!/bin/sh

# read -e -p "DIR: " DIR
# read -p "Apps: " APPS
# read -p "ENV: " ENV
# read -p "ECR: " ECR
# read -p "REGION: " REGION
# DIR=../../rivierapartners/api \
# APPS="api_web api_workers api_multi"
ECR=937487381041.dkr.ecr.us-west-2.amazonaws.com
REGION=us-west-2
ENV=staging
ORG=rivierapartners

ruby manifests/setup.rb
