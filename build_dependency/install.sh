#!/bin/bash

source ${SCRIPTS_PATH}/shared/validate_variables.sh

# Function to download and unzip the specified version if not already present
function download_and_extract() {
    local base_dir=$1
    local version=$2
    local versions_file=$3

    #validate_variable "BUILD_RESOURCES_PATH"

    # Check if the specified version directory already exists
    local target_dir="${base_dir}/${version}"
    if [ -d "$target_dir" ]; then
        echo "Directory $target_dir already exists. Skipping download."
        return 0
    fi

    # Get the download link from the versions file
    local link=$(grep "^${version}=" "$versions_file" | cut -d '=' -f2-)

    if [ -z "$link" ]; then
        echo "No download link found for version $version in $versions_file."
        return 1
    fi

    # Validate that the link ends with ".tar.gz"
    if [[ ! "$link" =~ \.tar\.gz$ ]]; then
        echo "Invalid link format: $link. Must end with .tar.gz"
        return 1
    fi
    # Create the target directory
    mkdir -p "$target_dir"

    # Download and unzip the file
    local temp_file=$(mktemp)
    echo "Downloading $link..."
    curl -L "$link" -o "$temp_file" --progress-bar
    echo "Extracting to $target_dir..."
    tar -xzf "$temp_file" -C "$target_dir" --strip-components=1

    # Clean up
    rm "$temp_file"

    echo "Downloaded and extracted $version to $target_dir."
}

#============ CUSTOM BUILD TOOLS which requires cache ============

# Function to install specific JDK version
install_jdk_version() {
  validate_variable "BUILD_RESOURCES_PATH"
  validate_variable "JDK_VERSION"

  local base_dir="${BUILD_RESOURCES_PATH}/jdk/${version}"
  local version="${JDK_VERSION}"
  local versions_file="${SCRIPTS_PATH}/customize/jdk_versions.txt"

  download_and_extract $base_dir $version $versions_file

  # Set environment variables
  export JAVA_HOME="${base_dir}"
  export PATH="${base_dir}/bin:$PATH"
}

# Function to install specific Maven version
install_maven_version() {
  validate_variable "BUILD_RESOURCES_PATH"
  validate_variable "MAVEN_VERSION"

  local base_dir="${BUILD_RESOURCES_PATH}/maven/${version}"
  local version="${MAVEN_VERSION}"
  local versions_file="${SCRIPTS_PATH}/customize/maven_versions.txt"

  download_and_extract $base_dir $version $versions_file

  # Set environment variables
  export M2_HOME="${base_dir}"
  export PATH="${base_dir}/bin:$PATH"
}