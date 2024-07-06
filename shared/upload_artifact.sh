#!/bin/bash

# Function to upload artifact
upload_artifact() {
    local filepath="$1"
    local filename=$(basename "$filepath")
    local api_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/artifacts"
    local token="${GITHUB_TOKEN}"

    echo "Uploading artifact: $filename"
    curl -sSL \
        -X POST \
        -H "Authorization: token $token" \
        -H "Content-Type: application/zip" \
        --data-binary "@$filepath" \
        "${api_url}?artifact_name=$filename"
}

# Main script execution starts here
if [ $# -ne 1 ]; then
    echo "Usage: $0 <file_path>"
    exit 1
fi

file_path="$1"

# Check if file exists
if [ ! -f "$file_path" ]; then
    echo "File not found: $file_path"
    exit 1
fi

# Call the function to upload artifact
upload_artifact "$file_path"
