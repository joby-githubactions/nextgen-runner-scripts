#!/bin/bash
set -e  # comment to avoid exit on any error

#SCRIPTS_PATH="${HOME}/actions-runner/scripts"

source ${SCRIPTS_PATH}/docker/env_variables_docker.sh

# Source the shared scripts
source ${SCRIPTS_PATH}/shared/validate_variables.sh
source ${SCRIPTS_PATH}/shared/utils.sh
source ${SCRIPTS_PATH}/tools/trivy_scan.sh

#------------------------EXPECTED VARIABLES-----------------------
validate_variable "APPLICATION_NAME"
validate_variable "IMAGE_TAG"
validate_variable "IMAGE_LATEST_TAG"
validate_variable "DOCKER_IMAGE_PUSH_PREFIX"

validate_variable "IMAGE_PULL_TAG"
validate_variable "DOCKER_IMAGE_PULL_PREFIX"
#----------------------EO-EXPECTED VARIABLES----------------------

#DOCKER_IMAGE_PUSH_PREFIX &  DOCKER_IMAGE_PUSH_PREFIX are from azure-pipelines.yaml
pull_image="$DOCKER_IMAGE_PULL_PREFIX/$APPLICATION_NAME:$IMAGE_PULL_TAG"
push_image="$DOCKER_IMAGE_PUSH_PREFIX/$APPLICATION_NAME:$IMAGE_TAG"
push_image_latest="$DOCKER_IMAGE_PUSH_PREFIX/$APPLICATION_NAME:$IMAGE_LATEST_TAG"

print_color "32;1" "Pulling Docker Image: ${pull_image}"
docker pull "$pull_image"
run_trivy_scan "$pull_image"

print_color "32;1" "Retaging Docker Image: ${pull_image} => ${push_image}"
docker tag "$pull_image" "$push_image"
print_color "32;1" "Pushing Docker Image: $push_image"
docker push $push_image

print_color "32;1" "Retaging Docker Image: ${push_image} => ${push_image_latest}"
docker tag "$push_image" "$push_image_latest"
print_color "32;1" "Pushing Docker Image: $push_image_latest"
docker push $push_image_latest