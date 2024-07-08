#!/bin/bash

source ${SCRIPTS_PATH}/build_dependency/install_jdk.sh
source ${SCRIPTS_PATH}/build_dependency/install_maven.sh
source ${SCRIPTS_PATH}/build_dependency/install_nodejs.sh
source ${SCRIPTS_PATH}/build_dependency/install_ng.sh

# Function to build a Maven project
build_maven() {
  echo "Detected Maven project. Running mvn package..."
  export MAVEN_VERSION="${MAVEN_VERSION:-3.8.4}"
  export JDK_VERSION="${JDK_VERSION:-17}"
  install_jdk_version
  install_maven_version
  
  mvn package
  if [ $? -ne 0 ]; then
    echo "Maven build failed."
    exit 1
  fi
}

# Function to build an Angular project
build_angular() {
  echo "Detected Angular project. Running ng build..."
  export NG_VERSION="${NG_VERSION:-11.2.5}"
  
  install_nodejs_version
  install_ng_version

  ng build
  if [ $? -ne 0 ]; then
    echo "Angular build failed."
    exit 1
  fi
}

# Function to build a Node.js project
build_node() {
  echo "Detected Node.js project. Running npm build..."
  export NODEJS_VERSION="${NODEJS_VERSION:-14.17.3}"

  install_nodejs_version
  
  npm run build
  if [ $? -ne 0 ]; then
    echo "Node.js build failed."
    exit 1
  fi
}
#========================================================================================
# Main function to determine the project type and call the appropriate build function
if [ -f "pom.xml" ]; then
  build_maven
elif [ -f "angular.json" ]; then
  build_angular
elif [ -f "package.json" ]; then
  build_node
else
  echo "No recognizable project type detected."
  exit 1
fi
