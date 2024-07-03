#!/bin/bash
#set -e

# Source the shared scripts
source shared/env_variables.sh
source shared/utils.sh

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

echo "Creating cicd_resources_path folder"

# Define paths
#-----------------------CICD_RESOURCES_PATH------------------------
resource_path=$(pwd)
template_folder="$resource_path/cicd-resources-template"
cicd_resources_path="$resource_path/cicd-resources"

rm -rf "$cicd_resources_path"
cp -r $template_folder $cicd_resources_path

chartfolder=$cicd_resources_path"/helm-template"

#-----------------------ENV_VARIABLES------------------------

cd $BUILD_SOURCESDIRECTORY
git_committer_name=$(gitCommitterName)
git_committer_email=$(gitCommitterEmail)
git_commit_url=$(gitCommitUrl)
git_commit_message=$(gitCommitMessage)
cd $resource_path
#---- Git info received
namespace="dod"

source_branch=$(basename "$BUILD_SOURCEBRANCH")
pipeline_id=$(echo $BUILD_BUILDNUMBER | sed 's/refs\/heads\///')
application_name=$BUILD_REPOSITORY_NAME

#-----------------------CICD_RESOURCES_PATH------------------------
echo "Source directory : $BUILD_SOURCESDIRECTORY"
echo "Source branch    : $BUILD_SOURCEBRANCH"

# development|release|production
environment_stage=$BUILD_ENVIRONMENT
autoscaling_enabled=true

resource_requests_cpu="${RESOURCE_REQUESTS_CPU:-100m}"
resource_requests_memory="${RESOURCE_REQUESTS_MEMORY:-300Mi}"
resource_limits_cpu="${RESOURCE_LIMITS_CPU:-500m}"
resource_limits_memory="${RESOURCE_LIMITS_MEMORY:-512Mi}"

resource_requests_cpu="${RESOURCE_REQUESTS_CPU:-200m}"
resource_requests_memory="${RESOURCE_REQUESTS_MEMORY:-512Mi}"
resource_limits_cpu="${RESOURCE_LIMITS_CPU:-500m}"
resource_limits_memory="${RESOURCE_LIMITS_MEMORY:-1Gi}"

# Set default values or use actual values
custom_project_variables=$PROJECT_VARIABLES
docker_host=${DOCKER_IMAGE_PUSH_PREFIX:-blueharvest}
image_repository="$docker_host/$BUILD_REPOSITORY_NAME"
image_pull_policy="${IMAGE_PULL_POLICY:-Always}"
image_tag="${IMAGE_TAG:-$pipeline_id}"
application_port="${APPLICATION_PORT:-8080}"
application_health_port="${APPLICATION_HEALTH_PORT:-$application_port}"
application_health_liveness_path="${APPLICATION_HEALTH_LIVENESS_PATH:-/actuator/info}"
application_health_liveness_delay="${APPLICATION_HEALTH_LIVENESS_DELAY:-40}"
application_health_readiness_path="${APPLICATION_HEALTH_READINESS_PATH:-/actuator/health}"
application_health_readiness_delay="${APPLICATION_HEALTH_READINESS_DELAY:-40}"
image_pull_secrets="${IMAGE_PULL_SECRETS:-image-pull-secret}"
host_names="${HOST_NAMES:-''}"

autoscaling_enabled="${AUTOSCALING_ENABLED:-$autoscaling_enabled}"
config_server_username="${CONFIG_SERVER_USERNAME:-config}"
config_server_password="${CONFIG_SERVER_PASSWORD:-password}"

#### HELM Specific params
helm_chart="${resource_path}/${application_name}-${pipeline_id}.tgz"
helm_oci_url="oci://$docker_host/helm/"

##### Escape slash #######
application_health_readiness_path=$(escape_slashes "$application_health_readiness_path")
application_health_liveness_path=$(escape_slashes "$application_health_liveness_path")
image_repository=$(escape_slashes "$image_repository")

###### PRINT ENV VARIABLES ##########

# Print variable values in a nice format with color
print_color "31;1" "Namespace:                      $namespace"
print_color "32;1" "Source Branch:                  $BUILD_SOURCEBRANCH"
print_color "32;1" "Enviornment Stage:              $environment_stage"
print_color "32;1" "Pipeline ID:                    $pipeline_id"
print_color "32;1" "Application Name:               $application_name"

print_color "33;1" "Project Variables:              $custom_project_variables"

print_color "34;1" "Image Repository:               $image_repository"
print_color "34;1" "Image Tag:                      $image_tag"
print_color "34;1" "Image Pull Policy:              $image_pull_policy"
print_color "34;1" "Image Pull Secrets:             $image_pull_secrets"

print_color "36;1" "Application Health Port:        $application_health_port"
print_color "36;1" "Liveness Probe Path:            $application_health_liveness_path"
print_color "36;1" "Liveness Probe Delay:           $application_health_liveness_delay"
print_color "36;1" "Readiness Probe Path:           $application_health_readiness_path"
print_color "36;1" "Readiness Probe Delay:          $application_health_readiness_delay"
print_color "36;1" "Application Port:               $application_port"
print_color "34;1" "Host Names:                     $host_names"
print_color "34;1" "Resource Requests (CPU):        $resource_requests_cpu"
print_color "34;1" "Resource Requests (MEMORY):     $resource_requests_memory"
print_color "34;1" "Resource Limits (CPU):          $resource_limits_cpu"
print_color "34;1" "Resource Limits (Memory):       $resource_limits_memory"
print_color "34;1" "Autoscaling Enabled:            $autoscaling_enabled"
print_color "35;1" "Config Server Username:         $config_server_username"
print_color "35;1" "Config Server Password:         ********************"

print_color "33;1" "Git Committer Name:             $git_committer_name"
print_color "33;1" "Git Committer Email:            $git_committer_email"
print_color "33;1" "Git Commit URL:                 $git_commit_url"
print_color "33;1" "Git Commit Message:             $git_commit_message"

print_color "35;1" "Helm Chart:                     $helm_chart"
print_color "35;1" "Helm OCI URL:                   $helm_oci_url"

###### /PRINT ENV VARIABLES ##########


###### HELM Chart ADJUSTMENTS ##########
#-----_helpers.tpl-------#
echo "Adjusting helpers.tpl"
_helpers_file=$chartfolder/templates/_helpers.tpl
temp_helpers_file=$(mktemp /tmp/_helpers_file.tpl.XXXXXX)

sed -e "s/##ENVIORNMENT_STAGE##/$environment_stage/g" \
    -e "s/##APPLICATION_NAME##/$application_name/g" \
    "$_helpers_file" > "$temp_helpers_file"
mv "$temp_helpers_file" "$_helpers_file"


#-----Chart.yaml-------#
echo "Adjusting Chart.yaml"
chart_yaml_file=$chartfolder/Chart.yaml
temp_chart_file=$(mktemp /tmp/Chart.yaml.XXXXXX)

# Use sed to replace variables in the values file
sed -e "s|##APPLICATION_NAME##|${application_name}|g" \
    -e "s|##PIPELINE_ID##|${pipeline_id}|g" \
    -e "s|##MAINTAINER_NAME##|${git_committer_name}|g" \
    -e "s|##MAINTAINER_EMAIL##|${git_committer_email}|g" \
    -e "s|##CHART_VERSION##|${pipeline_id}|g" \
    "$chart_yaml_file" > "$temp_chart_file"
mv "$temp_chart_file" "$chart_yaml_file"



#-----values.yaml-------#
echo "Adjusting values.yaml"
# Set the path to your YAML file
values_yaml_file=$chartfolder/values.yaml
temp_file=$(mktemp /tmp/application.yaml.XXXXXX)

# Set default values or use actual values
sed -e "s/##IMAGE_REPOSITORY##/$image_repository/g" \
    -e "s/##IMAGE_PULL_POLICY##/$image_pull_policy/g" \
    -e "s/##IMAGE_TAG##/$image_tag/g" \
    -e "s/##APPLICATION_HEALTH_PORT##/$application_health_port/g" \
    -e "s/##APPLICATION_HEALTH_LIVENESS_PATH##/$application_health_liveness_path/g" \
    -e "s/##APPLICATION_HEALTH_LIVENESS_DELAY##/$application_health_liveness_delay/g" \
    -e "s/##APPLICATION_HEALTH_READINESS_PATH##/$application_health_readiness_path/g" \
    -e "s/##APPLICATION_HEALTH_READINESS_DELAY##/$application_health_readiness_delay/g" \
    -e "s/##IMAGE_PULL_SECRETS##/$image_pull_secrets/g" \
    -e "s/##APPLICATION_PORT##/$application_port/g" \
    -e "s/##APPLICATION_NAME##/$application_name/g" \
    -e "s/##APPLICATION_HEALTH_READINESS_PATH##/$application_health_readiness_path/g" \
    -e "s/##HOST_NAMES##/$host_names/g" \
    -e "s/##RESOURCE_REQUESTS_CPU##/$resource_requests_cpu/g" \
    -e "s/##RESOURCE_REQUESTS_MEMORY##/$resource_requests_memory/g" \
    -e "s/##RESOURCE_LIMITS_CPU##/$resource_limits_cpu/g" \
    -e "s/##RESOURCE_LIMITS_MEMORY##/$resource_limits_memory/g" \
    -e "s/##AUTOSCALING_ENABLED##/$autoscaling_enabled/g" \
    -e "s/##CONFIG_SERVER_USERNAME##/$config_server_username/g" \
    -e "s/##CONFIG_SERVER_PASSWORD##/$config_server_password/g" \
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

# Package Helm chart
helm package ./cicd-resources/helm-template/

# Save Helm chart to OCI registry (README [Use OCI-based registries]: https://helm.sh/docs/topics/registries/)
#https://github.com/argoproj/argo-cd/issues/12634  ( there is a bug in listing - which will be resolved soon )
echo "Helm chart has been packaged and now trying to push to ACR. ($helm_oci_url)"
#helm push $helm_chart $helm_oci_url

if helm push $helm_chart $helm_oci_url; then
    echo "Helm template has been built and pushed to ACR successfully."
    rm -rf $helm_chart
else
    echo "Error: Helm push failed. Terminating further process."
    exit 1
fi
