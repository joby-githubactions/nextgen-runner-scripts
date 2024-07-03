#!/bin/bash
set -e  # comment to avoid exit on any error

SCRIPT_PATH="${HOME}/nextgen-runner-scripts"
source ${SCRIPT_PATH}/docker/env_variables_docker.sh

# Source the shared scripts
source ${SCRIPT_PATH}/shared/validate_variables.sh
source ${SCRIPT_PATH}/shared/utils.sh
source ${SCRIPT_PATH}/tools/trivy_scan.sh

#------------------------EXPECTED VARIABLES-----------------------
validate_variable "APPLICATION_NAME"
validate_variable "IMAGE_TAG"
validate_variable "IMAGE_LATEST_TAG"
validate_variable "DOCKER_IMAGE_PUSH_PREFIX"

validate_variable "DOCKER_FILE_PATH"
#----------------------EO-EXPECTED VARIABLES----------------------

#DOCKER_IMAGE_PUSH_PREFIX &  DOCKER_IMAGE_PUSH_PREFIX are from azure-pipelines.yaml
push_image="$DOCKER_IMAGE_PUSH_PREFIX/$APPLICATION_NAME:$IMAGE_TAG"
push_image_latest="$DOCKER_IMAGE_PUSH_PREFIX/$APPLICATION_NAME:$IMAGE_LATEST_TAG"

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
