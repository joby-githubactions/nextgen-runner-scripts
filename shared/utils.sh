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
