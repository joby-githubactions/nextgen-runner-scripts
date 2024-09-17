#!/bin/bash

source ${SCRIPTS_PATH}/shared/git_helpers.sh
source ${SCRIPTS_PATH}/customize/version.sh


# Retrieve the passed arguments (artifacts_path and destination_path)
artifacts_path="$1"
destination_path="$2"

# Define your variables for the JSON file
name="${APPLICATION_NAME:-$(get_git_repository_name)}"
version="$(get_build_version)"
branch="$(get_git_branch_name)"
commit="$(get_git_commit_id)"
commiter="$(get_git_committer_email)"
commitmessage="$(get_git_commit_message)"

# Create the JSON structure
json_content=$(cat <<EOF
{
  "name": "$name",
  "version": "$version",
  "branch": "$branch",
  "commit": "$commit",
  "commiter": "$commiter",
  "commitmessage": "$commitmessage"
}
EOF
)

# Write the JSON content to a file
echo "$json_content" > "$artifacts_path/info"

# Optional: Output a success message
echo "info json has been created at $artifacts_path"
