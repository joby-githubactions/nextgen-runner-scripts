#!/bin/bash

#SCRIPT_PATH="${HOME}/scripts"

# Source utils.sh for utility functions
source "${SCRIPT_PATH}/shared/utils.sh"

validate_variable() {
    local var_name="$1"
    local var_value="${!var_name}"  # Get the value of the variable using indirect reference

    if [ -z "$var_value" ]; then
        print_color "31;1" "ERROR: ${var_name} is not defined or empty. Please provide a value for ${var_name}."
        exit 1
    else
        print_color "36;1" "${var_name}: ${var_value}"
    fi
}
