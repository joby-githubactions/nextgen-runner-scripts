#!/bin/bash
set -e  # Exit on any error

source "${SCRIPTS_PATH}/shared/utils.sh"

# Function to handle the build process It will be called only when there is a BUILD_SCRIPT variable is available
function run_custom_build_script {
    validate_variable "BUILD_SCRIPT"
    print_step "Running Image Custom Build Script"

    local buildscript_folder_path="$(get_artifacts_path)/buildscript"
    local script_content="${BUILD_SCRIPT}"
    local script_path="${buildscript_folder_path}/build_script.sh"

    mkdir -p "${buildscript_folder_path}"
    
    echo "BUILD_SCRIPT is set. Creating and executing build_script.sh..."

    # Write the content to the temporary file
    echo "$script_content" > "$script_path"

    # Make the script executable
    chmod +x "$script_path"

    # Execute the build script
    "$script_path"
}