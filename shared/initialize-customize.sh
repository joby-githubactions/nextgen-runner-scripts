#!/bin/bash

# Ensure the script exits if any command fails
set -e

# -----------------------REFERANCE VARIABLES-----------------------

#Running the scheduler continuously
#nohup ${SCRIPTS_PATH}/scheduler/setup_custom_scripts.sh > ~/custom_scripts_sync.log 2>&1 &

# Check if NEXTGEN_RUNNER_CUSTOM_SCRIPTS_URL is set and CUSTOMIZE_FOLDER does not exist
#if [ -n "$NEXTGEN_RUNNER_CUSTOM_SCRIPTS_URL" ] && [ ! -d "$CUSTOMIZE_FOLDER" ]; then
#    echo "Cloning repository from ${NEXTGEN_RUNNER_CUSTOM_SCRIPTS_URL} into ${CUSTOMIZE_FOLDER}."
#    git clone "$NEXTGEN_RUNNER_CUSTOM_SCRIPTS_URL" "$CUSTOMIZE_FOLDER"
#    find ${CUSTOMIZE_FOLDER} -name "*.sh" -exec chmod +x {} \;
#        
#    if [ -d "$CUSTOMIZE_FOLDER/bin" ] && [ "$(ls -A $CUSTOMIZE_FOLDER/bin)" ]; then
#        chmod +x "$CUSTOMIZE_FOLDER/bin"/*
#        mv "$CUSTOMIZE_FOLDER/bin"/* "/usr/local/bin"
#    fi
#fi

source ${SCRIPTS_PATH}/customize/version.sh
source ${SCRIPTS_PATH}/shared/utils.sh

# Get the build version and version file path
build_version="$(get_build_version)"
artifacts_path="$(get_artifacts_path)"
version_file="$artifacts_path/version.txt"

print_step "Build Version : ${build_version}"

# Check if the version file does not exist or if the build version differs
if [ ! -f "$version_file" ] || [ "$build_version" != "$(cat $version_file)" ]; then
    print_color "32;1" "Cleaning artifacts folder"
    rm -rf ${artifacts_path}/*
    # Create the directory if it does not exist
    mkdir -p "$artifacts_path"
    print_color "32;1" "Creating or updating version file ${version_file} with build version ${build_version}"
    # Check if the file exists, and create it if it does not
    echo "$build_version" > "$version_file"
fi
