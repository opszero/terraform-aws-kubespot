FROM gcr.io/${PROJECT_ID}/${BASE_IMAGE}:${DOCKER_TAG}

COPY scripts /scripts
COPY rails /rails
