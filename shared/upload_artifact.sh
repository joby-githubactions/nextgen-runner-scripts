#!/bin/bash

source "${SCRIPTS_PATH}/shared/utils.sh"

# Function to upload artifact
function upload_artifact() {
    local token="token-${GITHUB_TOKEN}"
    
    print_color "32;1" "$token"

    print_color "32;1" "Uploading artifact: $filename"


    local filepath="$1"
    local filename=$(basename "$filepath")
    local api_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/artifacts"
    local token="${GITHUB_TOKEN}"

    print_color "32;1" "Uploading artifact: $filename"

    curl -sSL \
        -X POST \
        -H "Authorization: token $token" \
        -H "Content-Type: application/zip" \
        --data-binary "@$filepath" \
        "${api_url}?artifact_name=$filename"
}