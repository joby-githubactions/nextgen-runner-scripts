#!/bin/bash

set -e 

source ${SCRIPTS_PATH}/build_dependency/install.sh

# Function to build a Maven project
build_maven() {
  echo "Detected Maven project. Running mvn package..."
  install_maven_version 
  install_jdk_version 
  mvn package
}

#========================================================================================
# Main function to determine the project type and call the appropriate build function
if [ -f "pom.xml" ]; then
  build_maven
else
  echo "No recognizable auto build project type detected."
fi
