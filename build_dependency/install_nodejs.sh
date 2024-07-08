#!/bin/bash

source ${SCRIPTS_PATH}/shared/validate_variables.sh

# Function to install specific Node.js version
install_nodejs_version() {
  validate_variable "NODEJS_VERSION"

  local version="${NODEJS_VERSION}"
  local node_dir="${BUILD_RESOURCES_PATH}/node-v${version}-linux-x64"
  
  if [ -d "${node_dir}" ]; then
    echo "Node.js ${version} already installed."
  else
    echo "Node.js ${version} not found. Installing..."
    NODE_URL="https://nodejs.org/dist/v${version}/node-v${version}-linux-x64.tar.xz"
    NODE_ARCHIVE="${BUILD_RESOURCES_PATH}/node-v${version}-linux-x64.tar.xz"
    
    # Download Node.js archive if not already present
    wget -q --show-progress --progress=bar:force:noscroll -O "${NODE_ARCHIVE}" "${NODE_URL}"
    if [ $? -ne 0 ]; then
      echo "Failed to download Node.js ${version}."
      exit 1
    fi
    
    # Extract Node.js
    tar -xf "${NODE_ARCHIVE}" -C "${BUILD_RESOURCES_PATH}"
    if [ $? -ne 0 ]; then
      echo "Failed to extract Node.js ${version}."
      exit 1
    fi
    
    echo "Node.js ${version} installed."
  fi
  
  # Set environment variables
  export NODE_HOME="${node_dir}"
  export PATH="${node_dir}/bin:$PATH"
}

# install_nodejs_version "${version}"
