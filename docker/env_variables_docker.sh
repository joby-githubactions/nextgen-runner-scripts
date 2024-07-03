#!/bin/bash

# Source utils.sh for utility functions
source ~/shared/git_helpers.sh

# -----------------------MANDATORY VARIABLES-----------------------

#Note: Based on the branching stratergy IMAGE_PULL_TAG needed to be provided 
IMAGE_PULL_TAG="${IMAGE_PULL_TAG}"

# Note: Based on the branching stratergy DOCKER_IMAGE_PUSH_PREFIX needed to be provided 
DOCKER_IMAGE_PUSH_PREFIX="${DOCKER_IMAGE_PUSH_PREFIX}"

# ------------------CUSTOMIZABLE VARIABLES-------------------

# IMAGE_NAME: Use get_git_repository_name function output as default if IMAGE_NAME is not already set
IMAGE_NAME="${IMAGE_NAME:-$(get_git_repository_name)}"

# IMAGE_LATEST_TAG: Use get_git_branch_name function output as default if IMAGE_LATEST_TAG is not already set
IMAGE_LATEST_TAG="${IMAGE_LATEST_TAG:-$(get_git_branch_name)}"

# IMAGE_TAG: Use GITHUB_RUN_ID as default if IMAGE_TAG is not already set (for GitHub Actions pipeline run ID)
IMAGE_TAG="${IMAGE_TAG:-${GITHUB_RUN_ID}}"

# DOCKER_FILE_PATH: Use current directory (.) as default if DOCKER_FILE_PATH is not already set
DOCKER_FILE_PATH="${DOCKER_FILE_PATH:-.}"

# Note: ITs used for multi repository support, pulling from one repository and pusing to another repository - For multi repo support
DOCKER_IMAGE_PULL_PREFIX="${DOCKER_IMAGE_PULL_PREFIX:-${DOCKER_IMAGE_PUSH_PREFIX}}"


# Export variables to make them available to subsequent scripts or commands
export IMAGE_NAME
export IMAGE_LATEST_TAG
export IMAGE_TAG
export DOCKER_FILE_PATH
export IMAGE_PULL_TAG
export DOCKER_IMAGE_PUSH_PREFIX
export DOCKER_IMAGE_PULL_PREFIX