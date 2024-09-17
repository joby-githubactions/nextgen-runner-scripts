#!/bin/bash
set -e 
source ${SCRIPTS_PATH}/shared/utils.sh

# Define the function to generate the Dockerfile
generate_dockerfile() {

    validate_variable "CICD_ACTION"

    if [ "$CICD_ACTION" = "build_artifacts" ]; then
        echo "build_artifacts action don't needed to generate a Dockerfile"
        return 0  # Exit the function
    fi
    # Check if the correct number of arguments is provided
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 <folder> <version>"
        exit 1
    fi
    # Assign arguments to variables
    local docker_images_folder=$1
    local version_in_baseImages=$2

    local destination_path="$(get_workspace_path)"
    local destination_dockerfile_path="${destination_path}/Dockerfile"
    local artifacts_path="$(get_artifacts_path)/docker/"
    rm -rf $artifacts_path

    if [ ! -f "$destination_dockerfile_path" ]; then
        
        print_step "Generating Dockerfile for Version : $version_in_baseImages"

        local version="$version_in_baseImages"
        local template_folder="${CUSTOMIZE_FOLDER}/docker_images/$docker_images_folder"
        local baseimages_file="${template_folder}/baseimages.txt"
        local dockerfile_template="${template_folder}/Dockerfile"
        # Read the base image corresponding to the version

        local base_image=$(grep "^${version}=" "$baseimages_file" | cut -d'=' -f2)
        echo "Dockerfile template will be used from : ${template_folder}"
        if [ -z "$base_image" ]; then
            echo "Error: No base image found for version ${version} in ${baseimages_file} file"
            return 1
        fi
        # Create the artifacts directory if it doesn't exist
        mkdir -p "$artifacts_path"
        cp -r "$template_folder/"* "$artifacts_path/"
        rm -rf "${artifacts_path}/baseimages.txt"
        rm -rf "${artifacts_path}/Dockerfile"
        # Replace the placeholder in the Dockerfile template with the actual base image
        sed "s|##BASE_IMAGE##|${base_image}|g" "$dockerfile_template" > "${artifacts_path}/Dockerfile"
        echo "Dockerfile has been generated at ${artifacts_path}/Dockerfile"

        # Check if the configure.sh file exists
        if [ -f "$artifacts_path/configure.sh" ]; then
            "$artifacts_path/configure.sh" "$artifacts_path" "$destination_path"
        fi

        cp -r "$artifacts_path/"* "$destination_path/"
        echo "Dockerfile has been moved to $destination_dockerfile_path"
    else
        echo "Dockerfile already exists $destination_dockerfile_path"
    fi
}



# Call the function with provided arguments
#generate_dockerfile "$1" <= jdk as example
