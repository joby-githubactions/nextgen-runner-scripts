#!/bin/bash

set -e  # comment to avoid exit on any error

#SCRIPTS_PATH="${HOME}/scripts"

source ${SCRIPTS_PATH}/helm/env_variables_helm.sh
source ${SCRIPTS_PATH}/shared/validate_variables.sh
source ${SCRIPTS_PATH}/shared/utils.sh

###########################################################
#
#               CUSTOM_PROJECT_VARIABLES
###########################################################
#
# Functionality:
#   - Dynamically binds environment variables and creates Kubernetes secrets based on the GitLab Runner branch.
#   - Facilitates deployment of applications with different configurations without script modification.
#
# Example JSON `CUSTOM_PROJECT_VARIABLES`:
# {
#   "development": {
#     "secrets": {
#       "DATABASE_URL": "jdbc:mysql://localhost:3306/mydatabase",
#       "REDIS_HOST": "localhost",
#       "API_KEY": "abc123"
#     },
#     "envs": {
#       "DATABASE_URL": "jdbc:mysql://localhost:3306/mydatabase",
#       "REDIS_HOST": "localhost",
#       "API_KEY": "abc123"
#     }
#   },
#   "master": {
#     "envs": {
#       "DATABASE_URL": "jdbc:mysql://localhost:3306/mydatabase",
#       "REDIS_HOST": "localhost",
#       "API_KEY": "aas"
#     }
#   }
# }
#
# Note:
#   - Customize `CUSTOM_PROJECT_VARIABLES` with actual sensitive information for `DATABASE_URL`, `REDIS_HOST`, `API_KEY`, and any other variables required by your project.
#   - Secrets (`secrets` key) will create Kubernetes secrets and bind them to the deployment.
#   - Environment variables (`envs` key) will configure environment variables attached to the deployment YAML.
###########################################################



# dos2unix deploy.sh

# Define paths
#-----------------------CICD_RESOURCES_PATH------------------------
helm_reference_template_folder="${SCRIPTS_PATH}/helm/helm-reference-template"
output_folder="${ARTIFACTS_PATH}"
helm_template_folder="${output_folder}/helm-template"

echo "Copying ${helm_reference_template_folder} to ${helm_template_folder}"

rm -rf "${helm_template_folder}"
mkdir -p "${helm_template_folder}"
cp -r ${helm_reference_template_folder}/* ${helm_template_folder}

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
validate_variable "HELM_OCI_URL"

#This will be used for custom properties for different enviornments on the deployment side
environment_stage="${SOURCE_BRANCH}"
chart_version="${BUILD_VERSION}-helm"

print_color "32;1" "Building Helm Template: ${helm_template_folder}"

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
    -e "s|##CHART_VERSION##|${chart_version}|g" \
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
    -e "s/##INGRESS_HOST##/$INGRESS_HOST/g" \
        "$values_yaml_file" > "$temp_file"

# Check if the INGRESS_HOST variable is set
if [ -n "$INGRESS_HOST" ]; then
  echo "INGRESS_HOST is set to $INGRESS_HOST"
  # Replace the empty hosts array with the INGRESS_HOST value
  sed -i "" "s/hosts: \[\]/hosts:\n    - \"$INGRESS_HOST\"/" "$temp_file"
  echo "Added $INGRESS_HOST to ingress.hosts in $temp_file"
fi

# Check if the IMAGE_PULL_SECRET variable is set
if [ -n "$IMAGE_PULL_SECRET" ]; then
  echo "IMAGE_PULL_SECRET is set to $IMAGE_PULL_SECRET"

  # Replace empty imagePullSecrets array with the IMAGE_PULL_SECRET value
  sed -i "" "s/imagePullSecrets: \[\]/imagePullSecrets:\n  - $IMAGE_PULL_SECRET/" "$VALUES_FILE"
  echo "Added $IMAGE_PULL_SECRET to imagePullSecrets in $VALUES_FILE"
else
  echo "IMAGE_PULL_SECRET is not set. Removing imagePullSecrets from $VALUES_FILE."
  
  # Remove the entire line containing imagePullSecrets: [] from values.yaml
  sed -i "" "/imagePullSecrets: \[\]/d" "$VALUES_FILE"
fi

###### ADDING SECRETS ##########
echo "$environment_stage:" >> "$temp_file"

echo "  secrets:" >> "$temp_file"
secrets=$(echo "$CUSTOM_PROJECT_VARIABLES" | jq -r --arg env "$environment_stage" '.[$env].secrets')
# Iterate over each key-value pair in dev secrets and print
echo "$secrets" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | while IFS="=" read -r key value; do
    echo "    $key: $value" >> "$temp_file"
done
###### END OF SECRETS ADDITION ##########

###### ADDING CONFIGMAPS ##########
echo "  env:" >> "$temp_file"
envs=$(echo "$CUSTOM_PROJECT_VARIABLES" | jq -r --arg env "$environment_stage" '.[$env].envs')
# Iterate over each key-value pair in dev secrets and print
echo "$envs" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | while IFS="=" read -r key value; do
    echo "    $key: $value" >> "$temp_file"
done
###### END OF CONFIGMAPS ADDITION ##########

mv "$temp_file" "$values_yaml_file"

print_color "32;1" "Deployment vaiables"

cat $values_yaml_file

helm template ${helm_template_folder}

# Package Helm chart
helm_chart_name="${APPLICATION_NAME}-${chart_version}.tgz"
helm_chart_location="$(pwd)/${helm_chart_name}"
helm_chart="${output_folder}/${helm_chart_name}"

print_color "32;1" "Packaging helm template: ${helm_chart_name}"
helm package ${helm_template_folder}


mv "${helm_chart_location}" "${output_folder}/"
print_color "32;1" "Auto Generated Helm Chart Location: ${helm_chart}"


# Save Helm chart to OCI registry (README [Use OCI-based registries]: https://helm.sh/docs/topics/registries/)
#https://github.com/argoproj/argo-cd/issues/12634  ( there is a bug in listing - which will be resolved soon )
print_color "32;1"  "Pushing Helm chart to $HELM_OCI_URL"
#helm push $helm_chart $helm_oci_url

if helm push $helm_chart $HELM_OCI_URL; then
    print_color "32;1"  "Helm template has been built and pushed to the registry."
else
    echo "Error: Helm push failed. Terminating further process."
    exit 1
fi
