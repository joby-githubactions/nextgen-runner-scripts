#!/bin/bash

set -e

################################################################################
# This script automates the process of configuring AWS CLI, obtaining an ECR
# password, logging into Docker, creating an ECR repository, logging into Helm,
# and creating an ArgoCD repository using kubectl.
#
# The following functions are included in the script which is mandatory to keep:
# 1. docker_login: Logs into Docker using the ECR password.
# 2. create_repository: Creates an ECR repository if it doesn't already exist.
# 3. helm_login: Logs into Helm.
# 4. argocd_repo_create: Creates an ArgoCD repository using kubectl.
#
# Variables to be set before running the script:
# - AWS_ACCESS_KEY_ID: Your AWS access key ID.
# - AWS_SECRET_ACCESS_KEY: Your AWS secret access key.
# - AWS_ASSUME_ROLE_ARN: Assume role to have ecr access.
# - DOCKER_IMAGE_PUSH_PREFIX: Your ECR Registry hostname.
# - APPLICATION_NAME: The name of the application (used for ECR repository).
#
# Main execution sequence:
# - docker_login
# - create_repository
# - helm_login
# - argocd_repo_create
################################################################################

source ${SCRIPTS_PATH}/shared/utils.sh


# Function to assume role, set AWS credentials, and get ECR authentication token
function assume_ecr_access_role() {

    AWS_DEFAULT_REGION="eu-central-1"

    print_color "37;1" "Configuring AWS CLI..." >/dev/null
    aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" >/dev/null
    aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" >/dev/null
    aws configure set default.region "$AWS_DEFAULT_REGION" >/dev/null

    print_color "37;1" "Assuming Role $AWS_ASSUME_ROLE_ARN" >/dev/null

    # Assume role and capture JSON output
    assume_role_output=$(AWS_PAGER="" aws sts assume-role  --role-arn "$AWS_ASSUME_ROLE_ARN"  --role-session-name "nextgen-runner-ecr-access-role")

    # Check if assume role was successful
    if [ $? -ne 0 ]; then
        echo "Failed to assume role"
        exit 1
    fi

    # Extract and set AWS credentials and region in one line
    export AWS_ACCESS_KEY_ID=$(echo "$assume_role_output" | jq -r '.Credentials.AccessKeyId') \
        AWS_SECRET_ACCESS_KEY=$(echo "$assume_role_output" | jq -r '.Credentials.SecretAccessKey') \
        AWS_SESSION_TOKEN=$(echo "$assume_role_output" | jq -r '.Credentials.SessionToken') \
        AWS_REGION="$AWS_DEFAULT_REGION"

    # Optional: Print the assumed role details
    print_color "37;1" "Assumed Role:" >/dev/null
    print_color "37;1" "  Assumed Role ID: $(echo "$assume_role_output" | jq -r '.AssumedRoleUser.AssumedRoleId')" >/dev/null
    print_color "37;1" "  Arn: $(echo "$assume_role_output" | jq -r '.AssumedRoleUser.Arn')" >/dev/null    

}

# Function to get ECR password and save it in /secrets file if older than 1 hour
function get_ecr_password() {
    
    assume_ecr_access_role

    SECRETS_FILE="${SCRIPTS_PATH}/secrets/ecr-password"

    # Check if the secrets file is created within the last hour ( last 55 minutes )
    if [ ! -f "$SECRETS_FILE" ] || [ $(find "$SECRETS_FILE" -mmin +55 2>/dev/null) ]; then
        #print_color "37;1" "Fetching new ECR login password..."
        
        ECR_PASSWORD=$(AWS_PAGER="" aws ecr get-login-password)
        if [ $? -ne 0 ]; then
            echo "Error: Failed to get ECR login password."
            exit 1
        fi
        mkdir -p "$(dirname "$SECRETS_FILE")"
        echo "$ECR_PASSWORD" > "$SECRETS_FILE"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to write ECR password to secrets file."
            exit 1
        fi
    else
        ECR_PASSWORD=$(cat "$SECRETS_FILE")
        if [ $? -ne 0 ]; then
            echo "Error: Failed to read ECR password from secrets file."
            #Retrying for the first time
            ECR_PASSWORD=$(AWS_PAGER="" aws ecr get-login-password)
            echo "$ECR_PASSWORD" > "$SECRETS_FILE"
        fi
    fi

    echo "$ECR_PASSWORD"
}

##=================================================KEEP THE BELOW FUNCTIONS AS IS (Atleast the names)==============================================
# GLOBAL Function to login to Docker
function docker_login() {
    validate_variable "DOCKER_IMAGE_PUSH_PREFIX"
    print_color "37;1" "Logging into Docker..."
    ECR_PASSWORD=$(get_ecr_password)
    echo $ECR_PASSWORD | docker login --username AWS --password-stdin ${DOCKER_IMAGE_PUSH_PREFIX}
}

# GLOBAL Function to create a repository if it doesn't already exist
function create_repository() {
    validate_variable "APPLICATION_NAME"

    #Assume the role to switch user 
    assume_ecr_access_role

    print_color "37;1" "Checking if Docker repository exists..."    
    if aws ecr describe-repositories --repository-names "${APPLICATION_NAME}" >/dev/null 2>&1; then
        print_color "33;1" "Repository ${APPLICATION_NAME} already exists."
    else
        print_color "37;1" "Creating Docker repository ${APPLICATION_NAME}..."
        aws ecr create-repository --repository-name "${APPLICATION_NAME}"
        print_color "32;1" "Repository ${APPLICATION_NAME} created successfully."
    fi
}

# GLOBAL Function to login to Helm
function helm_login() {
    print_color "37;1" "Logging into Helm..."
    # Assumes Helm is configured to use a repository that requires authentication
    validate_variable "DOCKER_IMAGE_PUSH_PREFIX"
    ECR_PASSWORD=$(get_ecr_password)
    helm registry login -u AWS -p "${ECR_PASSWORD}" "${DOCKER_IMAGE_PUSH_PREFIX}"
}

# GLOBAL Function to create an ArgoCD repository using kubectl
function argocd_repo_create() {
    print_color "37;1" "Creating ArgoCD repository using kubectl..."
    validate_variable "DOCKER_IMAGE_PUSH_PREFIX"
    
    REPO_SECRETS_FILE="${SCRIPTS_PATH}/secrets/ecr-oci-repo-secret.yaml"
    # Remove existing file if it exists
    rm -f "$REPO_SECRETS_FILE"

    kubectl create secret generic "$DOCKER_IMAGE_PUSH_PREFIX" \
    --namespace=argocd \
    --from-literal=enableOCI='true' \
    --from-literal=name="$DOCKER_IMAGE_PUSH_PREFIX" \
    --from-literal=password="$(get_ecr_password)" \
    --from-literal=project='default' \
    --from-literal=type='helm' \
    --from-literal=url="$DOCKER_IMAGE_PUSH_PREFIX" \
    --from-literal=username='AWS' \
    --dry-run=client -o yaml \
    | sed 's/^  name: '"$DOCKER_IMAGE_PUSH_PREFIX"'$/  annotations:\n    managed-by: argocd.argoproj.io\n  labels:\n    argocd.argoproj.io\/secret-type: repository\n&/' \
    > $REPO_SECRETS_FILE

    # Apply the Kubernetes Secret using kubectl
    kubectl apply -n argocd -f $REPO_SECRETS_FILE
}


#====================install function from build_dependency will be called this function ======================
# Function to download a build dependency
function download_build_dependency() {
    #Links are from buid_dependency_versions (xx_versions.txt)

    local link="$1"
    local temp_file="$2"

    # Check if the link is an S3 URL
    if [[ "$link" == s3://* ]]; then
        
        echo "Downloading from s3 bucket" 
        # Check if AWS_SESSION_TOKEN is configured
        if [ -z "$AWS_SESSION_TOKEN" ]; then
            echo "AWS_SESSION_TOKEN is not set. Continuing with role assume."
            assume_ecr_access_role
        fi

        # Use aws s3 cp to download the file
        aws s3 cp "$link" "$temp_file"
        # Check if the download was successful
        if [ $? -ne 0 ]; then
            echo "Error: Failed to download file from S3."
            return 1
        fi
    else
        curl -L "$link" -o "$temp_file" --progress-bar
        # Check if the download was successful
        if [ $? -ne 0 ]; then
            echo "Error: Failed to download file using curl."
            return 1
        fi
    fi
    echo "File downloaded successfully to $temp_file"
    return 0
}

# Main execution
#docker_login
#create_repository
#helm_login
#argocd_repo_create
