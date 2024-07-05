#!/bin/bash

set -e  # comment to avoid exit on any error

#SCRIPTS_PATH="${HOME}/scripts"

source ${SCRIPTS_PATH}/helm/env_variables_helm.sh

# Source the shared scripts
source ${SCRIPTS_PATH}/shared/validate_variables.sh

#-----------------------Expected Variables------------------------
#BUILD_SOURCEBRANCH='development'
#BUILD_BUILDNUMBER='20231205.7'
#BUILD_REPOSITORY_NAME="hell0-world"
#PROJECT_VARIABLES='{"dev":{"secrets":{"DATABASE_URL":"jdbc:mysql://localhost:3306/mydatabase","REDIS_HOST":"localhost","API_KEY":"abc123"},"envs":{"DATABASE_URL":"jdbc:mysql://localhost:3306/mydatabase","REDIS_HOST":"localhost","API_KEY":"abc123"}},"qa":{"envs":{"DATABASE_URL":"jdbc:mysql://localhost:3306/mydatabase","REDIS_HOST":"localhost","API_KEY":"aas"}},"envs":{"env":{"DATABASE_URL":"jdbc:mysql://localhost:3306/mydatabase","REDIS_HOST":"localhost","API_KEY":"prod"}}}'

# TEST
#source_dir="/Users/joby/Documents/data/projects/helm/cicd-resources-template"
#destination_dir="./cicd-resources-template"
#rm -rf $destination_dir
#mkdir -p "$destination_dir"
#cp -r "$source_dir"/* "$destination_dir"
# call helmBuildAndPush.sh
#-----------------------Expected Variables------------------------

# dos2unix deploy.sh

# Define paths
#-----------------------CICD_RESOURCES_PATH------------------------
helm_reference_template_folder="${SCRIPTS_PATH}/helm/helm-reference-template"
helm_template_folder="${SCRIPTS_PATH}/outputs/helm-template"

echo "Copying ${helm_reference_template_folder} to ${helm_template_folder}"

rm -rf "${helm_template_folder}"
mkdir -p "${helm_template_folder}"
cp -r ${helm_reference_template_folder} ${helm_template_folder}

#-----------------------ENV_VARIABLES------------------------

# Escape slashes in paths if needed
export APPLICATION_HEALTH_READINESS_PATH=$(escape_slashes "$APPLICATION_HEALTH_READINESS_PATH")
export APPLICATION_HEALTH_LIVENESS_PATH=$(escape_slashes "$APPLICATION_HEALTH_LIVENESS_PATH")
export IMAGE_REPOSITORY=$(escape_slashes "$IMAGE_REPOSITORY")

# Validate and print all unique variables
validate_variable "BUILD_VERSION"
validate_variable "NAMESPACE"
validate_variable "DOCKER_IMAGE_PUSH_PREFIX"
validate_variable "APPLICATION_NAME"
validate_variable "CUSTOM_PROJECT_VARIABLES"
validate_variable "IMAGE_REPOSITORY"
validate_variable "IMAGE_TAG"
validate_variable "IMAGE_PULL_POLICY"
validate_variable "IMAGE_PULL_SECRETS"
validate_variable "APPLICATION_PORT"
validate_variable "APPLICATION_HEALTH_PORT"
validate_variable "APPLICATION_HEALTH_LIVENESS_PATH"
validate_variable "APPLICATION_HEALTH_LIVENESS_DELAY"
validate_variable "APPLICATION_HEALTH_READINESS_PATH"
validate_variable "APPLICATION_HEALTH_READINESS_DELAY"
validate_variable "RESOURCE_REQUESTS_CPU"
validate_variable "RESOURCE_REQUESTS_MEMORY"
validate_variable "RESOURCE_LIMITS_CPU"
validate_variable "RESOURCE_LIMITS_MEMORY"
validate_variable "AUTOSCALING_ENABLED"
validate_variable "GIT_COMMITTER_NAME"
validate_variable "GIT_COMMITTER_EMAIL"
validate_variable "GIT_COMMIT_URL"
validate_variable "GIT_COMMIT_MESSAGE"
validate_variable "SOURCE_BRANCH"
validate_variable "HELM_CHART"
validate_variable "HELM_OCI_URL"

#This will be used for custom properties for different enviornments on the deployment side
environment_stage=$SOURCE_BRANCH

###### HELM Chart ADJUSTMENTS ##########
#-----_helpers.tpl-------#
echo "Adjusting helpers.tpl"
_helpers_file=$helm_template_folder/templates/_helpers.tpl
temp_helpers_file=$(mktemp /tmp/_helpers_file.tpl.XXXXXX)

sed -e "s/##ENVIORNMENT_STAGE##/$environment_stage/g" \
    -e "s/##APPLICATION_NAME##/$APPLICATION_NAME/g" \
    "$_helpers_file" > "$temp_helpers_file"
mv "$temp_helpers_file" "$_helpers_file"

#-----Chart.yaml-------#
echo "Adjusting Chart.yaml"
chart_yaml_file=$helm_template_folder/Chart.yaml
temp_chart_file=$(mktemp /tmp/Chart.yaml.XXXXXX)

# Use sed to replace variables in the values file
sed -e "s|##APPLICATION_NAME##|${APPLICATION_NAME}|g" \
    -e "s|##BUILD_VERSION##|${BUILD_VERSION}|g" \
    -e "s|##MAINTAINER_NAME##|${GIT_COMMITTER_NAME}|g" \
    -e "s|##MAINTAINER_EMAIL##|${GIT_COMMITTER_EMAIL}|g" \
    -e "s|##CHART_VERSION##|${BUILD_VERSION}|g" \
    "$chart_yaml_file" > "$temp_chart_file"
mv "$temp_chart_file" "$chart_yaml_file"

#-----values.yaml-------#
echo "Adjusting values.yaml"
# Set the path to your YAML file
values_yaml_file=$helm_template_folder/values.yaml
temp_file=$(mktemp /tmp/application.yaml.XXXXXX)

# Set default values or use actual values
sed -e "s/##IMAGE_REPOSITORY##/$IMAGE_REPOSITORY/g" \
    -e "s/##IMAGE_PULL_POLICY##/$IMAGE_PULL_POLICY/g" \
    -e "s/##IMAGE_TAG##/$IMAGE_TAG/g" \
    -e "s/##APPLICATION_HEALTH_PORT##/$APPLICATION_HEALTH_PORT/g" \
    -e "s/##APPLICATION_HEALTH_LIVENESS_PATH##/$APPLICATION_HEALTH_LIVENESS_PATH/g" \
    -e "s/##APPLICATION_HEALTH_LIVENESS_DELAY##/$APPLICATION_HEALTH_LIVENESS_DELAY/g" \
    -e "s/##APPLICATION_HEALTH_READINESS_PATH##/$APPLICATION_HEALTH_READINESS_PATH/g" \
    -e "s/##APPLICATION_HEALTH_READINESS_DELAY##/$APPLICATION_HEALTH_READINESS_DELAY/g" \
    -e "s/##IMAGE_PULL_SECRETS##/$IMAGE_PULL_SECRETS/g" \
    -e "s/##APPLICATION_PORT##/$APPLICATION_PORT/g" \
    -e "s/##APPLICATION_NAME##/$APPLICATION_NAME/g" \
    -e "s/##RESOURCE_REQUESTS_CPU##/$RESOURCE_REQUESTS_CPU/g" \
    -e "s/##RESOURCE_REQUESTS_MEMORY##/$RESOURCE_REQUESTS_MEMORY/g" \
    -e "s/##RESOURCE_LIMITS_CPU##/$RESOURCE_LIMITS_CPU/g" \
    -e "s/##RESOURCE_LIMITS_MEMORY##/$RESOURCE_LIMITS_MEMORY/g" \
    -e "s/##AUTOSCALING_ENABLED##/$AUTOSCALING_ENABLED/g" \
        "$values_yaml_file" > "$temp_file"

###### ADDING SECRETS ##########
echo "$environment_stage:" >> "$temp_file"

echo "  secrets:" >> "$temp_file"
secrets=$(echo "$custom_project_variables" | jq -r --arg env "$environment_stage" '.[$env].secrets')
# Iterate over each key-value pair in dev secrets and print
echo "$secrets" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | while IFS="=" read -r key value; do
    echo "    $key: $value" >> "$temp_file"
done
###### END OF SECRETS ADDITION ##########

###### ADDING CONFIGMAPS ##########
echo "  env:" >> "$temp_file"
envs=$(echo "$custom_project_variables" | jq -r --arg env "$environment_stage" '.[$env].envs')
# Iterate over each key-value pair in dev secrets and print
echo "$envs" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | while IFS="=" read -r key value; do
    echo "    $key: $value" >> "$temp_file"
done
###### END OF CONFIGMAPS ADDITION ##########

mv "$temp_file" "$values_yaml_file"

echo "values.yaml after adjustments"
cat $values_yaml_file

helm template ${helm_template_folder}
# Package Helm chart
helm package ${helm_template_folder}

# Save Helm chart to OCI registry (README [Use OCI-based registries]: https://helm.sh/docs/topics/registries/)
#https://github.com/argoproj/argo-cd/issues/12634  ( there is a bug in listing - which will be resolved soon )
echo "Helm chart has been packaged and now trying to push to ACR. ($HELM_OCI_URL)"
#helm push $HELM_CHART $helm_oci_url

if helm push $HELM_CHART $HELM_OCI_URL; then
    echo "Helm template has been built and pushed to ACR successfully."
    rm -rf $HELM_CHART
else
    echo "Error: Helm push failed. Terminating further process."
    exit 1
fi
