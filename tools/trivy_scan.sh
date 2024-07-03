#!/bin/bash
set -e  # Exit on any error

SCRIPT_PATH="${HOME}/nextgen-runner-scripts"
source "${SCRIPT_PATH}/shared/utils.sh"

# Function to run Trivy vulnerability scan on a Docker image
function run_trivy_scan() {
    trivy_folder_path="${SCRIPT_PATH}/trivy/"
    
    # Create or clean up Trivy results directory
    rm -rf "${trivy_folder_path}"
    mkdir -p "${trivy_folder_path}"
    
    local docker_image="$1"
    local trivy_results_xml_path="${trivy_folder_path}report-high-crit.xml"
    local trivy_results_html_path="${trivy_folder_path}report-high-crit.html"

    # Print message indicating start of scanning
    print_color "32;1" "Scanning Docker Image: ${docker_image}"

    # Run Trivy scan and generate JUnit report
    trivy -d image --severity HIGH,CRITICAL --ignore-unfixed --format template --template @/usr/local/share/trivy/templates/junit.tpl -o "${trivy_results_xml_path}" "${docker_image}"

    # Run Trivy scan and generate HTML report
    trivy -d image --severity HIGH,CRITICAL --ignore-unfixed --format template --template @/usr/local/share/trivy/templates/html.tpl -o "${trivy_results_html_path}" "${docker_image}"

    # Print Trivy scan results in tabular format
    trivy -f table -d image --severity HIGH,CRITICAL "${docker_image}"

    # Check if Trivy identified HIGH or CRITICAL vulnerabilities
    if grep -q '<failure message="' "${trivy_results_xml_path}"; then
        # Print message about vulnerabilities found
        print_color "34;1" "Trivy found HIGH or CRITICAL vulnerabilities. Build failed."
        # Optionally exit the script if you want to fail the build
        # exit 1
    fi
}

# Check if script is being executed or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If script is executed directly, run Trivy scan with provided Docker image argument
    if [ $# -ne 1 ]; then
        echo "Usage: $0 <docker_image>"
        exit 1
    fi
    run_trivy_scan "$1"
fi

# Usage Example:
# ./trivy_scan.sh my-docker-image:latest
