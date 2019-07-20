#!/bin/bash

set -e

if [ -z "$AWS_SECRETS" ]
then
   AWS_SECRETS_FILE=${AWS_SECRETS_FILE:-".env.aws"}
   aws secretsmanager get-secret-value --secret-id "$AWS_SECRETS" | jq -r '.SecretString' > $AWS_SECRETS_FILE
   source $AWS_SECRETS_FILE
fi
