#!/bin/bash

set -e

PROJECT_ID=${PROJECT_ID:-"opszero/deploytag"}
DOCKER_FILE=${DOCKER_FILE:-"Dockerfile"}
CONTAINER_REGISTRY=${CONTAINER_REGISTRY:-"1234.dkr.ecr.us-west-2.amazonaws.com"}

set -x
docker build ${DOCKER_BUILD_ARGS} -t ${IMAGE} -f $DOCKER_FILE .

docker tag ${IMAGE} $CONTAINER_REGISTRY/${PROJECT_ID}/${IMAGE}:${CIRCLE_SHA1}
docker push $CONTAINER_REGISTRY/${PROJECT_ID}/${IMAGE}:${CIRCLE_SHA1}

CIRCLE_BRANCH=$(echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9_]/-/g')
docker tag ${IMAGE} $CONTAINER_REGISTRY/${PROJECT_ID}/${IMAGE}:${CIRCLE_BRANCH}
docker push $CONTAINER_REGISTRY/${PROJECT_ID}/${IMAGE}:${CIRCLE_BRANCH}

if [ "$CIRCLE_BRANCH" = "master" ]
then
    docker tag ${IMAGE} $CONTAINER_REGISTRY/${PROJECT_ID}/${IMAGE}:latest
    docker push $CONTAINER_REGISTRY/${PROJECT_ID}/${IMAGE}:latest
fi
