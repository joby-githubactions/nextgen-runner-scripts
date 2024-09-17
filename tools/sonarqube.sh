#!/bin/bash

#source ${SCRIPTS_PATH}/shared/git_helpers.sh
#source ${SCRIPTS_PATH}/shared/utils.sh

function run_sonar_checks(){
    export APPLICATION_NAME="nextgen-hello-world"
    export SONAR_HOST="https://sonarqube-itmp-agcs.devops-services.ec1.aws.aztec.cloud.allianz"
    export SONAR_TOKEN=""
    export SONAR_USERNAME="admin"
    export SONAR_PASSWORD="/0x"
    export BUILD_VERSION="1.0.0"
    export SONAR_PROJECT_KEY="nextgen_$(echo "$APPLICATION_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:]]\+/_/g')"
    create_project
    sonar_upload
}

function sonar_upload(){
    mvn sonar:sonar \
    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
    -Dsonar.projectName='${APPLICATION_NAME}' \
    -Dsonar.host.url=${SONAR_HOST} \
    -Dsonar.token=${SONAR_TOKEN} \
    -Dsonar.projectVersion=${BUILD_VERSION}
}

function create_project() {
    #print_step "Checking Sonarcube"
    echo "Checking Sonarcube"

    ENCODED_CREDS=$(echo -n "${SONAR_USERNAME}:${SONAR_PASSWORD}" | base64)
    AUTH_HEADER="Authorization: Basic ${ENCODED_CREDS}"

    URL='${SONAR_HOST}/api/projects/create'

    # Define the form data
    FORM_DATA=(
    --form 'name="${APPLICATION_NAME}"'
    --form 'project="${SONAR_PROJECT_KEY}"'
    --form 'visibility="private"'
    )

    # Make the curl request and capture the response status code and body
    response=$(curl --write-out "%{http_code}" --silent --output /tmp/curl_response.txt \
    --location "$URL" \
    --header "$AUTH_HEADER" \
    "${FORM_DATA[@]}")

    # Read the response body
    response_body=$(< /tmp/curl_response.txt)

    # Check if the status code is 400
    if [[ "$response" -eq 400 ]]; then
        # Check if the response body contains the specific error message
        if echo "$response_body" | grep -q 'A similar key already exists'; then
            echo "Error: A similar key already exists. Ignoring..."
        else
            echo "Received 400 Bad Request with a different error: $response_body"
        fi
    else
        echo "Response code: $response"
    fi

    # Clean up
    rm /tmp/curl_response.txt
}