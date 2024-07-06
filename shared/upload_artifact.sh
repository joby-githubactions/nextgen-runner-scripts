#!/bin/bash

source "${SCRIPTS_PATH}/shared/utils.sh"

upload_artifact() {
    local filepath="$1"
    local filename=$(basename "$filepath")
    local artifact_name="$filename"
    local repository="${GITHUB_REPOSITORY}"
    local token="${GITHUB_TOKEN}"
    local run_id="${GITHUB_RUN_ID}"
    local api_url="https://api.github.com/repos/${repository}/actions/runs/${run_id}/artifacts"

    # Determine content type
    local content_type="application/octet-stream"
    case "$filename" in
        *.html) content_type="text/html";;
        *.txt) content_type="text/plain";;
        *.json) content_type="application/json";;
        # Add more file types as needed
    esac

    # 2. Upload the artifact file
    curl -sSL -X PUT -H "Authorization: token ${token}" -H "Content-Type: ${content_type}" \
      --data-binary @"${filepath}" \
      "${api_url}"

    echo "Uploaded artifact: ${artifact_name}"
}
