#!/bin/bash
set -e

# Function to get the build version 
# NOTE : Ensures version starts with a number
function get_build_version() {
  local version="${APP_VERSION:-$GITHUB_RUN_NUMBER}"
  echo "${version}"
}
