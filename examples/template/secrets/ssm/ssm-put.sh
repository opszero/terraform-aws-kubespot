#!/usr/bin/env bash
#

export AWS_PROFILE=""

aws ssm put-parameter --name "$1" --value "$2" --type "SecureString" --tier Standard --overwrite
