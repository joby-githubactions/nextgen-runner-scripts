#!/bin/bash

CERTIFICATE_BASE_URL="https://rootca.allianz.com/download"
CERT_IMPORT_DIR="$SCRIPTS_PATH/certificates"

function import_certificate_if_needed() {
    local cert=$1
    local alias_name=$(echo $cert | sed 's/_base64//')
    local cert_file="${CERT_IMPORT_DIR}/${cert}"

    mkdir -p "$CERT_IMPORT_DIR"

    if keytool -list -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit -alias "$alias_name" > /dev/null 2>&1; then
        echo "Certificate ${alias_name} already exists in the keystore. Skipping import."
    else
        echo "Downloading ${alias_name} to ${cert_file}"
        curl -sS -o "${cert_file}" "${CERTIFICATE_BASE_URL}/${cert}" || {
            echo "Failed to download ${alias_name}"
            return 1
        }

        echo "Importing ${alias_name} into Java keystore"
        keytool -import -noprompt -v -trustcacerts -alias "$alias_name" -keystore "$JAVA_HOME/lib/security/cacerts" -file "$cert_file" -keypass changeit -storepass changeit || {
            echo "Failed to import ${alias_name} into Java keystore"
            return 1
        }
        echo "Successfully imported ${alias_name} into Java keystore"
    fi
}

function install_allianz_certificates() {
    import_certificate_if_needed Allianz_Group_Root_CA_II_base64.cer
    import_certificate_if_needed Allianz_Group_Infrastructure3_CA_base64.cer
    import_certificate_if_needed Allianz_Group_Infrastructure4_CA_base64.cer
    import_certificate_if_needed rootca3_base64.cer
    import_certificate_if_needed infraca5_base64.cer
    import_certificate_if_needed infraca5V_base64.cer
}
