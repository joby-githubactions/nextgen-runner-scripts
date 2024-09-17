#!/bin/sh

# Load the JSON content from data.json into UI_RUNTIME_PROPERTIES variable

# Method to process JSON and update files
process_json_and_update_files() {
  #echo "Running UI runtime properties replacement"
  #echo "$UI_RUNTIME_PROPERTIES"
  # Check if the JSON content is valid
  echo "$UI_RUNTIME_PROPERTIES" | jq empty > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Invalid JSON content or jq lib is not available"
    echo "$UI_RUNTIME_PROPERTIES"
    return  
  fi

  # Loop through each object in the JSON array
  echo "$UI_RUNTIME_PROPERTIES" | jq -c '.[]' | while read -r item; do
    # Extract the filepath
    filepath=$(echo "$item" | jq -r '.filepath')

    # Check if the file exists
    if [ -f "$filepath" ]; then
      echo "Processing file: $filepath"

      # Loop through each key-value pair in the values object
      echo "$item" | jq -r '.values | to_entries[] | "\(.key): \(.value)"' | while read -r pair; do
        key=$(echo "$pair" | cut -d ':' -f 1 | xargs)  # Extract the key
        value=$(echo "$pair" | cut -d ':' -f 2- | xargs)  # Extract the value

        # Replace the key with the value in the file using sed
        sed -i "s|$key|$value|g" "$filepath"

        # Print only the first few characters of the value for logging
        if [ "$(echo "$value" | wc -c)" -gt 5 ]; then
          masked_value=$(echo "$value" | cut -c 1-4) # Get first 4 characters
          masked_value="$masked_value... (hidden)"
        else
          masked_value="$value"
        fi

        # Print the replacement with masked value
        echo "  Replaced '$key' with '$masked_value' in $filepath"
      done
    else
      echo "File not found: $filepath"
    fi

    echo # Print a newline
  done
}

# Call the method
process_json_and_update_files

echo "Starting the Nginx server... 🚀"

nginx -g 'daemon off;'
