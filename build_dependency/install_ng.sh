#!/bin/bash

# Function to install specific version of Angular CLI (ng)
install_ng_version() {
  # Validate if NG_VERSION variable is set
  validate_variable "NG_VERSION"

  local version="$NG_VERSION"
  local ng_dir="${BUILD_RESOURCES_PATH}/angular-cli-${version}"

  # Check if Angular CLI is already installed
  if [ -x "$(command -v ng)" ]; then
    local current_version=$(ng version --version)
    echo "Angular CLI ${current_version} already installed."
    return
  fi

  echo "Angular CLI ${version} not found. Installing..."

  # Install Angular CLI globally using npm
  npm install -g @angular/cli@"$version"
  if [ $? -ne 0 ]; then
    echo "Failed to install Angular CLI ${version}."
    exit 1
  fi

  echo "Angular CLI ${version} installed successfully."

  # Optionally, you can set environment variables here if needed
}

# Example usage: Install Angular CLI 12.2.1
#install_ng_version "12.2.1"
