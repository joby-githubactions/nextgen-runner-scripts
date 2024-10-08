#!/bin/bash

set -e

# Source utils.sh for utility functions
source ${SCRIPTS_PATH}/shared/git_helpers.sh
source ${SCRIPTS_PATH}/customize/version.sh

# -----------------------REFERANCE VARIABLES-----------------------
export BUILD_VERSION="$(get_build_version)"

#to run git commands
export GIT_DIR="${GITHUB_WORKSPACE}/.git"
# -----------------------MANDATORY VARIABLES-----------------------

# Namespace
export NAMESPACE="${NAMESPACE}"

export DOCKER_IMAGE_PUSH_PREFIX="${DOCKER_IMAGE_PUSH_PREFIX}"  ##DOCKER_HOST

# ------------------CUSTOMIZABLE VARIABLES-------------------

# Application details
export APPLICATION_NAME="${APPLICATION_NAME:-$(get_git_repository_name)}"
export CUSTOM_PROJECT_VARIABLES="${CUSTOM_PROJECT_VARIABLES:-}"

# Docker and image details
export IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-$DOCKER_IMAGE_PUSH_PREFIX/$APPLICATION_NAME}"
export IMAGE_TAG="${IMAGE_TAG:-$BUILD_VERSION}"

export IMAGE_PULL_POLICY="${IMAGE_PULL_POLICY:-Always}"
export IMAGE_PULL_SECRETS="${IMAGE_PULL_SECRETS:-image-pull-secret}"

# Application ports and health checks
export APPLICATION_PORT="${APPLICATION_PORT:-8080}"
export APPLICATION_HEALTH_PORT="${APPLICATION_HEALTH_PORT:-$APPLICATION_PORT}"
export APPLICATION_HEALTH_LIVENESS_PATH="${APPLICATION_HEALTH_LIVENESS_PATH:-/actuator/info}"
export APPLICATION_HEALTH_LIVENESS_DELAY="${APPLICATION_HEALTH_LIVENESS_DELAY:-40}"
export APPLICATION_HEALTH_READINESS_PATH="${APPLICATION_HEALTH_READINESS_PATH:-/actuator/health}"
export APPLICATION_HEALTH_READINESS_DELAY="${APPLICATION_HEALTH_READINESS_DELAY:-40}"

# Resource requests and limits
export RESOURCE_REQUESTS_CPU="${RESOURCE_REQUESTS_CPU:-200m}"
export RESOURCE_REQUESTS_MEMORY="${RESOURCE_REQUESTS_MEMORY:-512Mi}"
export RESOURCE_LIMITS_CPU="${RESOURCE_LIMITS_CPU:-500m}"
export RESOURCE_LIMITS_MEMORY="${RESOURCE_LIMITS_MEMORY:-1Gi}"

# Autoscaling and configuration server
export AUTOSCALING_ENABLED="${AUTOSCALING_ENABLED:-true}"

# Git details
export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-$(get_git_committer_name)}"
export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-$(get_git_committer_email)}"
export GIT_COMMIT_URL="${GIT_COMMIT_URL:-$(get_git_commit_url)}"
export GIT_COMMIT_MESSAGE="${GIT_COMMIT_MESSAGE:-$(get_git_commit_message)}"
export SOURCE_BRANCH="${SOURCE_BRANCH:-$(get_git_branch_name)}"


# Helm details
export HELM_EXPERIMENTAL_OCI=1
export HELM_OCI_URL="${HELM_OCI_URL:-oci://${DOCKER_IMAGE_PUSH_PREFIX}}"

#Optional Ingress details
export INGRESS_HOST="${INGRESS_HOST}"

#Optional Image pull secret
export IMAGE_PULL_SECRET="${IMAGE_PULL_SECRET}"

#Optional config map or secret reference 
export CONFIG_MAP_REF_NAME="${CONFIG_MAP_REF_NAME}"
export SECRETS_REF_NAME="${SECRETS_REF_NAME}"

#Remember this shouldn't contain any space or special chars like '-'
export ENVIRONMENT_STAGE="${ENVIRONMENT_STAGE:-unknown}"

#Optional persistent volume claim
export PERSISTENT_VOLUME_CLAIM="${PERSISTENT_VOLUME_CLAIM:-}"
