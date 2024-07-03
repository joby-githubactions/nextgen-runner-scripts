#!/bin/bash

SCRIPT_PATH="${HOME}/nextgen-runner-scripts"

# Source utils.sh for utility functions
source ${SCRIPT_PATH}/shared/git_helpers.sh

# -----------------------REFERANCE VARIABLES-----------------------
export BUILD_VERSION="${GITHUB_RUN_ID}"

# -----------------------MANDATORY VARIABLES-----------------------

# Note: Based on the branching strategy IMAGE_PULL_TAG needed to be provided
export IMAGE_PULL_TAG="${IMAGE_PULL_TAG}"

# Note: Based on the branching strategy DOCKER_IMAGE_PUSH_PREFIX needed to be provided
export DOCKER_IMAGE_PUSH_PREFIX="${DOCKER_IMAGE_PUSH_PREFIX}"

# ------------------CUSTOMIZABLE VARIABLES-------------------

# APPLICATION_NAME: Use get_git_repository_name function output as default if APPLICATION_NAME is not already set
export APPLICATION_NAME="${APPLICATION_NAME:-$(get_git_repository_name)}"

# IMAGE_LATEST_TAG: Use get_git_branch_name function output as default if IMAGE_LATEST_TAG is not already set
export IMAGE_LATEST_TAG="${IMAGE_LATEST_TAG:-$(get_git_branch_name)}"

# IMAGE_TAG: Use GITHUB_RUN_ID as default if IMAGE_TAG is not already set (for GitHub Actions pipeline run ID)
export IMAGE_TAG="${IMAGE_TAG:-${BUILD_VERSION}}"

# DOCKER_FILE_PATH: Use current directory (.) as default if DOCKER_FILE_PATH is not already set
export DOCKER_FILE_PATH="${DOCKER_FILE_PATH:-.}"

# Note: ITs used for multi-repository support, pulling from one repository and pushing to another repository - For multi-repo support
export DOCKER_IMAGE_PULL_PREFIX="${DOCKER_IMAGE_PULL_PREFIX:-${DOCKER_IMAGE_PUSH_PREFIX}}"

# Set the DOCKER_HOST environment variable
export DOCKER_HOST="tcp://localhost:2375"