#!/bin/bash

# Source the generic.sh file
source generic.sh

# Set the DOCKER_HOST environment variable
export DOCKER_HOST="tcp://localhost:2375"

IMAGE_NAME="${IMAGE_NAME:-nextgen-image}"
IMAGE_LATEST_TAG="${IMAGE_LATEST_TAG:-latest}"
IMAGE_TAG="${IMAGE_TAG:-$IMAGE_LATEST_TAG}"
DOCKER_FILE_PATH="${DOCKER_FILE_PATH:-.}"

#DOCKER_IMAGE_PUSH_PREFIX &  DOCKER_IMAGE_PUSH_PREFIX are from azure-pipelines.yaml
push_image="$DOCKER_IMAGE_PUSH_PREFIX/$IMAGE_NAME:$IMAGE_TAG"
push_image_latest="$DOCKER_IMAGE_PUSH_PREFIX/$IMAGE_NAME:$IMAGE_LATEST_TAG"

# Use the environment variable in your script     # Set the Dockerfile path and tag for the Docker build
echo "Build Repository Local Path: $DOCKER_FILE_PATH"
docker_file="$DOCKER_FILE_PATH/Dockerfile"
docker build -f "$docker_file" -t "$push_image" "$DOCKER_FILE_PATH"
# Check the exit status of the docker build command

if [ $? -ne 0 ]; then
    echo "Docker build failed. Exiting..."
    exit 1
fi

run_trivy_scan "$push_image"
print_color "32;1" "Pushing Docker Image: $push_image"
docker push $push_image

docker tag "$push_image" "$push_image_latest"
print_color "32;1" "Pushing Docker Image: $push_image_latest"
docker push $push_image_latest
