#!/bin/bash

# Source the generic.sh file
source generic.sh

# Set the DOCKER_HOST environment variable
export DOCKER_HOST="tcp://localhost:2375"

IMAGE_NAME="${IMAGE_NAME:-nextgen-image}"
IMAGE_PULL_TAG="${IMAGE_PULL_TAG:-$IMAGE_LATEST_TAG}"
IMAGE_LATEST_TAG="${IMAGE_LATEST_TAG:-latest}"
IMAGE_TAG="${IMAGE_TAG:-$IMAGE_LATEST_TAG}"

#DOCKER_IMAGE_PUSH_PREFIX &  DOCKER_IMAGE_PUSH_PREFIX are from azure-pipelines.yaml
pull_image="$DOCKER_IMAGE_PULL_PREFIX/$IMAGE_NAME:$IMAGE_PULL_TAG"
push_image="$DOCKER_IMAGE_PUSH_PREFIX/$IMAGE_NAME:$IMAGE_TAG"
push_image_latest="$DOCKER_IMAGE_PUSH_PREFIX/$IMAGE_NAME:$IMAGE_LATEST_TAG"

docker pull "$pull_image"
run_trivy_scan "$pull_image"

docker tag "$pull_image" "$push_image"
print_color "32;1" "Pushing Docker Image: $push_image"
docker push $push_image

docker tag "$push_image" "$push_image_latest"
print_color "32;1" "Pushing Docker Image: $push_image_latest"
docker push $push_image_latest