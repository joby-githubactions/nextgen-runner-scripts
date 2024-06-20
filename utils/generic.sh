#!/bin/bash

function print_color() {
    color=$1
    text=$2
    echo -e "\033[${color}m${text}\033[0m"
}
function escape_slashes() {
    local input_string="$1"
    local escaped_string=$(echo "$input_string" | sed 's/\//\\\//g')
    echo "$escaped_string"
}

function gitCommitterName(){
    local git_committer_name=$(git -C . log -1 --pretty=format:'%an')
    echo "${git_committer_name//[^a-zA-Z]/_}"
}

function gitCommitterEmail(){
	local git_committer_email=$(git -C . log -1 --pretty=format:'%ae')
	echo "${git_committer_email}"
}

function gitCommitUrl(){
    local input_url=$(git config --get remote.origin.url)
    local git_hash_id=$(git rev-parse HEAD)
	echo "${input_url/tatasteel-dod@/}/commit/${git_hash_id}"
}

function gitCommitMessage(){
    local git_commit_message=$(git log -1 --pretty=%B)
    git_commit_message="$(echo "$git_commit_message" | tr -d '\n' | tr -d "'" | tr -d '"')"
    echo "${git_commit_message}"
}

function run_trivy_scan() {
    trivy_folder_path="$(pwd)/trivy/"
    
    rm -rf $trivy_folder_path
    mkdir -p "$trivy_folder_path"
    
    local docker_image="$1"
    local trivy_results_xml_path="${trivy_folder_path}report-high-crit.xml"
    local trivy_results_html_path="${trivy_folder_path}report-high-crit.html"

    print_color "32;1" "Scanning Docker Image: $docker_image"

    # Run Trivy scan and generate JUnit report
    trivy -d image --severity HIGH,CRITICAL --ignore-unfixed --format template --template @/usr/local/share/trivy/templates/junit.tpl -o "$trivy_results_xml_path" "$docker_image"

    # Run Trivy scan and generate Html report
    trivy -d image --severity HIGH,CRITICAL --ignore-unfixed --format template --template @/usr/local/share/trivy/templates/html.tpl -o "$trivy_results_html_path" "$docker_image"

    # Print Trivy scan results in tabular format
    trivy -f table -d image --severity HIGH,CRITICAL "$docker_image"

    # Check if Trivy identified HIGH or CRITICAL vulnerabilities
    if grep -q '<failure message="' "$trivy_results_xml_path"; then
        # Fail the build if vulnerabilities are found
        print_color "34;1" "Trivy found HIGH or CRITICAL vulnerabilities. Build failed."
       #Disabled the exit as of now
       # exit 1  
    fi
}
