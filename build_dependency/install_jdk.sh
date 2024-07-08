#!/bin/bash

source ${SCRIPTS_PATH}/shared/validate_variables.sh

# Function to install specific JDK version
install_jdk_version() {
  validate_variable "JDK_VERSION"
  local version="${JDK_VERSION}"
  local jdk_dir="${BUILD_RESOURCES_PATH}/jdk-${version}"
  
  if [ -d "${jdk_dir}" ]; then
    echo "Java JDK ${version} already installed."
  else
    echo "Java JDK ${version} not found. Installing..."
    JDK_URL="https://download.java.net/java/GA/jdk${version}/openjdk-${version}_linux-x64_bin.tar.gz"
    JDK_ARCHIVE="${BUILD_RESOURCES_PATH}/openjdk-${version}_linux-x64_bin.tar.gz"
    
    # Download JDK archive if not already present
    wget -q --show-progress --progress=bar:force:noscroll -O "${JDK_ARCHIVE}" "${JDK_URL}"
    if [ $? -ne 0 ]; then
      echo "Failed to download JDK ${version}."
      exit 1
    fi
    
    # Extract JDK
    tar -xf "${JDK_ARCHIVE}" -C "${BUILD_RESOURCES_PATH}"
    if [ $? -ne 0 ]; then
      echo "Failed to extract JDK ${version}."
      exit 1
    fi
    
    echo "Java JDK ${version} installed."
  fi
  
  # Set environment variables
  export JAVA_HOME="${jdk_dir}"
  export PATH="${jdk_dir}/bin:$PATH"
}

# install_jdk_version "${version}"
