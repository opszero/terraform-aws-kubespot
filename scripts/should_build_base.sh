#!/bin/bash

set -e

DEPENDENCIES_SHA1=$(git log -1 --format=format:%H --full-diff ./scripts/dependencies.sh)

if [ $DEPENDENCIES_SHA1 = $CIRCLE_SHA1 ]
then
    exit 0
else
    exit 1
fi
