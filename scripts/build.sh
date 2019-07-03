#!/bin/bash

set -e

export PROJECT_ID=${PROJECT_ID:-"tractionguest/deploy-machine"}
export CIRCLE_BRANCH=$(echo $CIRCLE_BRANCH | sed 's/[^A-Za-z0-9_]/-/g')
export CONTAINER_REGISTRY=${CONTAINER_REGISTRY:-"291031131640.dkr.ecr.us-west-2.amazonaws.com"}
export BASE_IMAGE=${IMAGE}_base

function image_exists(){
    if [ "$CLOUD_PROVIDER" = "gcp" ]
    then
        [ $(gcloud container images list-tags --filter="tags=($DOCKER_TAG)" "${CONTAINER_REGISTRY}/${PROJECT_ID}/${BASE_IMAGE}" | wc -l) -eq 0 ]
        return $?
    elif [ "$CLOUD_PROVIDER" = "aws" ]
    then
        #TODO
    else
        return 1
    fi

}

function should_build_base(){
    # If a Dockerfile.base exists
    if [ -e "Dockerfile.base" ]
    then
        # Check if a base image doesn't exist yet.
        if image_exists
        then
            return 0
        # Check if there's a custom script to build the base image
        elif [ -e "./scripts/should_build_base.sh" ]
        then
            ./scripts/should_build_base.sh
            return $?
        else
            # Otherwise compare the Dockerfile.base with the latest sha
            local BASE_COMMIT=$(git log -1 --format=format:%H --full-diff Dockerfile.base)
            if [ "$BASE_COMMIT" = "$CIRCLE_SHA1" || "$FORCE_BASE_BUILD" ]
            then
                return 0
            else
                return 1
            fi
        fi
    else
        return 1
    fi
}

function build_image(){
    local IMAGE=$1
    local DOCKER_FILE=$2

    docker build ${DOCKER_BUILD_ARGS} -t ${IMAGE} -f $DOCKER_FILE .

    docker tag ${IMAGE} ${CONTAINER_REGISTRY}/${PROJECT_ID}/${IMAGE}:${CIRCLE_SHA1}
    docker push ${CONTAINER_REGISTRY}/${PROJECT_ID}/${IMAGE}:${CIRCLE_SHA1}

    docker tag ${IMAGE} ${CONTAINER_REGISTRY}/${PROJECT_ID}/${IMAGE}:${CIRCLE_BRANCH}
    docker push ${CONTAINER_REGISTRY}/${PROJECT_ID}/${IMAGE}:${CIRCLE_BRANCH}

    if [ "$CIRCLE_BRANCH" = "master" ]
    then
        docker tag ${IMAGE} ${CONTAINER_REGISTRY}/${PROJECT_ID}/${IMAGE}:latest
        docker push ${CONTAINER_REGISTRY}/${PROJECT_ID}/${IMAGE}:latest
    fi
}

function docker_login(){
    if [ "$CLOUD_PROVIDER" = "gcp" ]
    then
        # Auth with GCLOUD
        gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://${CONTAINER_REGISTRY}
    elif [ "$CLOUD_PROVIDER" = "aws" ]
    then
        #TODO
    fi
}

function base_count(){
    if [ "$CLOUD_PROVIDER" = "gcp" ]
    then
        return $(gcloud container images list-tags --filter="tags=($CIRCLE_BRANCH)" --format="table[no-heading](digest)" "${CONTAINER_REGISTRY}/${PROJECT_ID}/${BASE_IMAGE}" | wc -l)
    elif [ "$CLOUD_PROVIDER" = "aws" ]
    then
        #TODO
    fi
}

docker_login

# If we've created a base image for this branch, let's use it. Otherwise use the latest base image.
base_count
if [ $? -gt 0 ]
then
    export DOCKER_TAG=$CIRCLE_BRANCH
else
    export DOCKER_TAG="latest"
fi

if should_build_base
then
    build_image $BASE_IMAGE Dockerfile.base
fi

cat Dockerfile | envsubst > Dockerfile.sub

build_image $IMAGE Dockerfile.sub
