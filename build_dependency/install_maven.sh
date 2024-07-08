#!/bin/bash

# Define the shared persistence volume directory
source ${SCRIPTS_PATH}/shared/validate_variables.sh

# Function to install specific Maven version
install_maven_version() {
  validate_variable "MAVEN_VERSION"
  local version="${MAVEN_VERSION}"
  local maven_dir="${BUILD_RESOURCES_PATH}/apache-maven-${version}"
  
  if [ -d "${maven_dir}" ]; then
    echo "Maven ${version} already installed."
  else
    echo "Maven ${version} not found. Installing..."
    MAVEN_BASE_URL="https://downloads.apache.org/maven/maven-3/${version}/binaries"
    MAVEN_URL="${MAVEN_BASE_URL}/apache-maven-${version}-bin.tar.gz"
    MAVEN_ARCHIVE="${BUILD_RESOURCES_PATH}/apache-maven-${version}-bin.tar.gz"
    
    # Download Maven archive if not already present
    wget -q --show-progress --progress=bar:force:noscroll -O "${MAVEN_ARCHIVE}" "${MAVEN_URL}"
    if [ $? -ne 0 ]; then
      echo "Failed to download Maven ${version}."
      exit 1
    fi
    
    # Extract Maven
    tar -xf "${MAVEN_ARCHIVE}" -C "${BUILD_RESOURCES_PATH}"
    if [ $? -ne 0 ]; then
      echo "Failed to extract Maven ${version}."
      exit 1
    fi
    
    echo "Maven ${version} installed."
  fi
  
  # Set environment variables
  export M2_HOME="${maven_dir}"
  export PATH="${maven_dir}/bin:$PATH"
}

# install_maven_version "${version}"