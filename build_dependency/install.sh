#!/bin/bash

source ${SCRIPTS_PATH}/shared/utils.sh
source ${SCRIPTS_PATH}/customize/auth_config.sh
source ${SCRIPTS_PATH}/shared/import_allianz_certificates_into_jdk.sh

# Function to download and unzip the specified version if not already present
function download_and_extract() {
    local base_dir=$1
    local version=$2
    local versions_file=$3

    #validate_variable "BUILD_RESOURCES_PATH"

    # Check if the specified version directory already exists
    local target_dir="${base_dir}"
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

    download_build_dependency $link $temp_file

    echo "Extracting to $target_dir..."
    tar -xzf "$temp_file" -C "$target_dir" --strip-components=1

    # Clean up
    rm "$temp_file"

    echo "Downloaded and extracted $version to $target_dir."
}

#============ CUSTOM BUILD TOOLS which requires cache ============
# Function to get the default version from the versions file
function get_default_version() {
    local versions_file="$1"
    grep "^default=" "$versions_file" | cut -d '=' -f2
}

#Customized version env variable : JDK_VERSION
# Function to install specific JDK version
export install_jdk_version_called=false
function install_jdk_version() {
  # Check if the function has already been called
  if [ "$install_jdk_version_called" = true ]; then
      return
  fi
  export install_jdk_version_called=true

  validate_variable "BUILD_RESOURCES_PATH"

  local versions_file="${SCRIPTS_PATH}/customize/build_dependency_versions/jdk_versions.txt"
  local version="${JDK_VERSION:-$(get_default_version "$versions_file")}"
  local base_dir="${BUILD_RESOURCES_PATH}/jdk/${version}"

  export JDK_VERSION="${version}"
  print_color "36;1" "JDK_VERSION: ${version}"

  if [ ! -d "$base_dir" ]; then
    download_and_extract $base_dir $version $versions_file
    # Set environment variables
    export JAVA_HOME="${base_dir}"
    export PATH="${base_dir}/bin:$PATH"
    install_allianz_certificates
  else
    echo "Directory $base_dir already exists. Skipping download and extraction. Setting JAVA_HOME and PATH"
    # Set environment variables
    export JAVA_HOME="${base_dir}"
    export PATH="${base_dir}/bin:$PATH"
  fi
}

#Customized version env variable : MAVEN_VERSION
# Function to install specific Maven version
export install_maven_version_called=false
function install_maven_version() {
  # Check if the function has already been called
  if [ "$install_maven_version_called" = true ]; then
      return
  fi
  export install_maven_version_called=true

  validate_variable "BUILD_RESOURCES_PATH"

  local versions_file="${SCRIPTS_PATH}/customize/build_dependency_versions/maven_versions.txt"
  local version="${MAVEN_VERSION:-$(get_default_version "$versions_file")}"
  local base_dir="${BUILD_RESOURCES_PATH}/maven/${version}"

  print_color "36;1" "MAVEN_VERSION: ${version}"

  download_and_extract $base_dir $version $versions_file

  # Set environment variables
  export M2_HOME="${base_dir}"
  export PATH="${base_dir}/bin:$PATH"
}

#Customized version env variable : NODE_VERSION
# Function to install specific Node.js version
export install_node_version_called=false
function install_node_version() {
  # Check if the function has already been called
  if [ "$install_node_version_called" = true ]; then
      return
  fi
  export install_node_version_called=true

  validate_variable "BUILD_RESOURCES_PATH"

  local versions_file="${SCRIPTS_PATH}/customize/build_dependency_versions/node_versions.txt"
  local version="${NODE_VERSION:-$(get_default_version "$versions_file")}"
  local base_dir="${BUILD_RESOURCES_PATH}/node/${version}"

  export NODE_VERSION=${version}
  print_color "36;1" "NODE_VERSION: ${version}"

  download_and_extract $base_dir $version $versions_file

  # Set environment variables
  export NODE_HOME="${base_dir}"
  export PATH="${base_dir}/bin:$PATH"
}

#Customized version env variable : ANGULAR_CLI_VERSION
# Function to install or switch to a specific Angular CLI version using npx
export install_angular_cli_version_called=false
function install_angular_cli_version() {
  # Check if the function has already been called
  if [ "$install_angular_cli_version_called" = true ]; then
      return
  fi
  export install_angular_cli_version_called=true

  validate_variable "NODE_HOME"
  
  local versions_file="${SCRIPTS_PATH}/customize/build_dependency_versions/angular_cli_versions.txt"
  local version="${ANGULAR_CLI_VERSION:-$(get_default_version "$versions_file")}"
  local cli_version=$(grep "^${version}=" "$versions_file" | cut -d '=' -f2)

  export INSTALLED_ANGULAR_CLI_VERSION=${version}
  print_color "36;1" "ANGULAR_CLI_VERSION: ${cli_version}"

  if [ -z "$cli_version" ]; then
      echo "No CLI version found for version $version in $versions_file."
      return 1
  fi

  echo "Checking if Angular CLI version $cli_version is installed..."
  if ! npm list -g @angular/cli@$cli_version > /dev/null 2>&1; then
    echo "Installing Angular CLI version $cli_version..."
    npm install -g @angular/cli@$cli_version
  else
    echo "Angular CLI version $cli_version is already installed."
  fi
}
