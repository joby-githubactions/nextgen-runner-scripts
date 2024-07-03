#!/bin/bash

# Source the shared scripts
source ~/docker/env_variables_docker.sh
source ~/docker/validate_variables.sh
source ~/shared/utils.sh
source ~/tools/trivy_scan.sh

#------------------------EXPECTED VARIABLES-----------------------
validate_variable "IMAGE_NAME"
validate_variable "IMAGE_TAG"
validate_variable "IMAGE_LATEST_TAG"
validate_variable "DOCKER_IMAGE_PUSH_PREFIX"

validate_variable "IMAGE_PULL_TAG"
validate_variable "DOCKER_IMAGE_PULL_PREFIX"
#----------------------EO-EXPECTED VARIABLES----------------------

# Set the DOCKER_HOST environment variable
export DOCKER_HOST="tcp://localhost:2375"

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