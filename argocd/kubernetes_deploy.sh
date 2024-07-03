#!/bin/bash
set -e  # comment to avoid exit on any error
SCRIPT_PATH="${HOME}/nextgen-runner-scripts"
source ${SCRIPT_PATH}/argocd/env_variables_argocd.sh

# Source the shared scripts
source ${SCRIPT_PATH}/shared/validate_variables.sh
source ${SCRIPT_PATH}/shared/utils.sh

argofolder="${SCRIPT_PATH}/argocd/argocd-template"

# Validate mandatory variables
#------------------------EXPECTED VARIABLES-----------------------
validate_variable "BUILD_VERSION"
validate_variable "DOCKER_IMAGE_PUSH_PREFIX"
validate_variable "NAMESPACE"
validate_variable "APPLICATION_NAME"
validate_variable "GIT_COMMITTER_NAME"
validate_variable "GIT_COMMITTER_EMAIL"
validate_variable "GIT_COMMIT_URL"
validate_variable "GIT_COMMIT_MESSAGE"
validate_variable "GIT_COMMIT_ID"
validate_variable "SOURCE_BRANCH"
#----------------------EO-EXPECTED VARIABLES----------------------

###### ARGOCD ADJUSTMENTS ##########
echo "Adjusting argocd application.yaml"
application_yaml_template=$argofolder/template-application.yaml
argocd_template=$argofolder/application.yaml
temp_file=$(mktemp /tmp/application.yaml.XXXXXX)
# Replace variables in the file using sed
sed \
    -e "s|##APPLICATION_NAME##|${APPLICATION_NAME}|g" \
    -e "s|##MAINTAINER_NAME##|${GIT_COMMITTER_NAME}|g" \
    -e "s|##MAINTAINER_EMAIL##|${GIT_COMMITTER_EMAIL}|g" \
    -e "s|##GIT_COMMIT_URL##|${GIT_COMMIT_URL}|g" \
    -e "s|##GIT_COMMIT_MESSAGE##|${GIT_COMMIT_MESSAGE}|g" \
    -e "s|##BUILD_VERSION##|${BUILD_VERSION}|g" \
    -e "s|##NAMESPACE##|${NAMESPACE}|g" \
    -e "s|##REPO_URL##|${DOCKER_IMAGE_PUSH_PREFIX}|g" \
    -e "s|##SOURCE_BRANCH##|${SOURCE_BRANCH}|g" \
    -e "s|##GIT_COMMIT_ID##|${GIT_COMMIT_ID}|g" \
    "${application_yaml_template}" > "$temp_file"
# Move the temporary file back to the original file
mv "$temp_file" "$argocd_template"

cat $argocd_template

print_color "32;1"  "Applying ArgoCD template"

kubectl apply -f $argocd_template