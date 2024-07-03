#!/bin/bash

# Function to print text in a specified color
function print_color() {
    local color="$1"
    local text="$2"
    echo -e "\033[${color}m${text}\033[0m"
}

# Function to escape slashes in a string
function escape_slashes() {
    local input_string="$1"
    local escaped_string=$(echo "$input_string" | sed 's/\//\\\//g')
    echo "$escaped_string"
}
