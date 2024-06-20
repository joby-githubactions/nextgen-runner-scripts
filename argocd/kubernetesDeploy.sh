#!/bin/bash
#set -e

# Source the generic.sh file
source generic.sh

resource_path=$(pwd)
argofolder=$resource_path"/argocd/argocd-template"
application_name=$BUILD_REPOSITORY_NAME

cd $BUILD_SOURCESDIRECTORY
git_committer_name=$(gitCommitterName)
git_committer_email=$(gitCommitterEmail)
git_commit_url=$(gitCommitUrl)
git_commit_message=$(gitCommitMessage)
pipeline_id=$(echo $BUILD_BUILDNUMBER | sed 's/refs\/heads\///')
namespace="dod"
docker_host=${DOCKER_IMAGE_PUSH_PREFIX:-blueharvest}
source_branch=$(basename "$BUILD_SOURCEBRANCH")
environment_stage=$BUILD_ENVIRONMENT


###### ARGOCD ADJUSTMENTS ##########
echo "Adjusting argocd application.yaml"
application_yaml_template=$argofolder/template-application.yaml
argocd_template=$argofolder/application.yaml
temp_file=$(mktemp /tmp/application.yaml.XXXXXX)
# Replace variables in the file using sed
sed \
    -e "s|##APPLICATION_NAME##|${application_name}|g" \
    -e "s|##MAINTAINER_NAME##|${git_committer_name}|g" \
    -e "s|##MAINTAINER_EMAIL##|${git_committer_email}|g" \
    -e "s|##GIT_COMMIT_URL##|${git_commit_url}|g" \
    -e "s|##GIT_COMMIT_MESSAGE##|${git_commit_message}|g" \
    -e "s|##PIPELINE_ID##|${pipeline_id}|g" \
    -e "s|##NAMESPACE##|${namespace}|g" \
    -e "s|##REPO_URL##|${docker_host}|g" \
    -e "s|##SOURCE_BRANCH##|${source_branch}|g" \
    -e "s|##ENVIRONMENT_STAGE##|${environment_stage}|g" \
    "${application_yaml_template}" > "$temp_file"
# Move the temporary file back to the original file
mv "$temp_file" "$argocd_template"

cat $argocd_template

print_color "32;1"  "Applying ArgoCD template"

kubectl apply -f $argocd_template