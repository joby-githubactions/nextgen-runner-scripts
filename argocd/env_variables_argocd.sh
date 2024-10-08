#!/bin/bash
set -e
# Source utils.sh for utility functions
source ${SCRIPTS_PATH}/shared/git_helpers.sh
source ${SCRIPTS_PATH}/customize/version.sh

# -----------------------REFERANCE VARIABLES-----------------------
export BUILD_VERSION="$(get_build_version)"
#to run git commands
export GIT_DIR="${GITHUB_WORKSPACE}/.git"
export PIPELINE_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
# -----------------------MANDATORY VARIABLES-----------------------
export DOCKER_IMAGE_PUSH_PREFIX="${DOCKER_IMAGE_PUSH_PREFIX}"  ##DOCKER_HOST
export NAMESPACE="${NAMESPACE}"
# ------------------CUSTOMIZABLE VARIABLES-------------------

# Load Git details using helper functions
export APPLICATION_NAME="${APPLICATION_NAME:-$(get_git_repository_name)}"
export ARGOCD_APPLICATION_NAME="${ARGOCD_APPLICATION_NAME:-}"
export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-$(get_git_committer_name)}"
export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-$(get_git_committer_email)}"
export GIT_COMMIT_URL="${GIT_COMMIT_URL:-$(get_git_commit_url)}"
export GIT_COMMIT_MESSAGE="${GIT_COMMIT_MESSAGE:-$(get_git_commit_message)}"
export SOURCE_BRANCH="${SOURCE_BRANCH:-$(get_git_branch_name)}"
export GIT_COMMIT_ID="${GIT_COMMIT_ID:-$(get_git_commit_id)}"
export GIT_COMMIT_SHORT_ID="${GIT_COMMIT_SHORT_ID:-$(get_git_commit_short_id)}"

export ARGOCD_PROJECT_NAME="${ARGOCD_PROJECT_NAME:-default}"