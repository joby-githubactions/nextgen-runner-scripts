#!/bin/bash
set -e  # comment to avoid exit on any error

source ${SCRIPTS_PATH}/argocd/env_variables_argocd.sh

# Source the shared scripts
source ${SCRIPTS_PATH}/shared/utils.sh
source ${SCRIPTS_PATH}/customize/auth_config.sh

print_step "Kubernetes Deploy"

#auth_config
argocd_repo_create

argo_reference_template_folder="${SCRIPTS_PATH}/argocd/argocd-reference-template/"
output_folder="$(get_artifacts_path)"

argo_template_folder="${output_folder}/argocd"

echo "Copying ${argo_reference_template_folder} to ${argo_template_folder}"

rm -rf "${argo_template_folder}"
mkdir -p "${argo_template_folder}"
cp -r ${argo_reference_template_folder}/* ${argo_template_folder}

# Validate mandatory variables
#------------------------EXPECTED VARIABLES-----------------------
validate_variable "BUILD_VERSION"
validate_variable "DOCKER_IMAGE_PUSH_PREFIX"
validate_variable "NAMESPACE"
validate_variable "APPLICATION_NAME"
validate_variable "GIT_COMMITTER_NAME"
validate_variable "GIT_COMMITTER_EMAIL"
validate_variable "GIT_COMMIT_MESSAGE"
validate_variable "SOURCE_BRANCH"
validate_variable "GIT_COMMIT_ID"
validate_variable "GIT_COMMIT_SHORT_ID"
validate_variable "PIPELINE_URL"
validate_variable "GIT_COMMIT_URL"
validate_variable "ARGOCD_PROJECT_NAME"
#----------------------EO-EXPECTED VARIABLES----------------------

argocd_app_name="${APPLICATION_NAME}"
# Create the app_name variable with conditional hyphen
if [ -n "$ARGOCD_APPLICATION_NAME" ]; then
    argocd_app_name="${ARGOCD_APPLICATION_NAME}"
fi

###### ARGOCD ADJUSTMENTS ##########
application_yaml=$argo_template_folder/application.yaml
echo "Adjusting argocd $application_yaml"
temp_file=$(mktemp /tmp/application.yaml.XXXXXX)
# Replace variables in the file using sed
sed \
    -e "s|##ARGOCD_APPLICATION_NAME##|${argocd_app_name}|g" \
    -e "s|##ARGOCD_PROJECT_NAME##|${ARGOCD_PROJECT_NAME}|g" \
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
    -e "s|##GIT_COMMIT_SHORT_ID##|${GIT_COMMIT_SHORT_ID}|g" \
    -e "s|##PIPELINE_URL##|${PIPELINE_URL}|g" \
    "${application_yaml}" > "$temp_file"
# Move the temporary file back to the original file
mv "$temp_file" "$application_yaml"

cat $application_yaml

print_color "32;1"  "Applying ArgoCD template"

kubectl apply -f $argo_template_folder

print_color "32;1" "Completed: Kubernetes Deploy"