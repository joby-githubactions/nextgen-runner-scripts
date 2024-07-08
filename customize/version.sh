#!/bin/bash

# Function to get the build version 
# NOTE : Ensures version starts with a number
function get_build_version() {
  echo "${GITHUB_RUN_NUMBER}"
}
