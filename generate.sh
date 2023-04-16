#! /usr/bin/env bash

DOMAINS=$1
CA_NAME=$2
PASS=$3
DAYS=${4:-3650}
OUTPUT_FOLDER="output/$CA_NAME/"
CERT_OUTPUT_FOLDER="output/$CA_NAME/certificates/"

red () {
    tput setaf 1
    echo $1
    tput init
}

green () {
    tput setaf 2
    echo $1
    tput init
}

cleanup() {
    rm -f "${OUTPUT_FOLDER}v3.ext" "${OUTPUT_FOLDER}ca.srl" "${CERT_OUTPUT_FOLDER}${MAIN_DOMAIN}.csr"
}

generateExtensionFile() {
    STRING=""
    if [ "$DOMAIN_COUNT" -gt 1 ]; then
        I=0
        for DOMAIN in "${DOMAIN_ARRAY[@]}"
        do
            STRING="${STRING}DNS.${I}=${DOMAIN}\n"
            I=$((I+1))
        done
        echo -e "[EXT]\nsubjectAltName=@alt_names\n[alt_names]\n${STRING}"
    else
        echo -e "[EXT]\nsubjectAltName=DNS.0:$MAIN_DOMAIN"
    fi
}

if [ -z "$DOMAINS" ]; then
    red "Domain(s) not specified, aborting."
    exit 1;
fi

if [ -z "$CA_NAME" ]; then
    red "CA name not specified, aborting."
    exit 1;
fi

if [ -z "$PASS" ]; then
    red "CA password not specified, aborting."
    exit 1;
fi

mkdir -p "$OUTPUT_FOLDER"
mkdir -p "$CERT_OUTPUT_FOLDER"

IFS=',' read -ra DOMAIN_ARRAY <<< "$DOMAINS"
DOMAIN_COUNT=${#DOMAIN_ARRAY[@]}
MAIN_DOMAIN="${DOMAIN_ARRAY[0]}"

if [[ ! -f "${OUTPUT_FOLDER}ca.pem" ]]; then
    if [[ ! -f "${OUTPUT_FOLDER}ca.key" ]]; then
        openssl genrsa -aes256 -passout "pass:$PASS" -out "${OUTPUT_FOLDER}ca.key" 4096
    fi
    openssl req -x509 -new -nodes -key "${OUTPUT_FOLDER}ca.key" -days "$DAYS" -passin "pass:$PASS" -out "${OUTPUT_FOLDER}ca.pem" -subj "/CN=$CA_NAME"
fi

if [[ -f "${OUTPUT_FOLDER}certificates/${MAIN_DOMAIN}.key" ]] || [[ -f "${CERT_OUTPUT_FOLDER}${MAIN_DOMAIN}.crt" ]]; then
    echo "Certificate for domain \"${MAIN_DOMAIN}\" already exists."
    exit 1;
fi

openssl req -nodes -newkey rsa:2048 -keyout "${CERT_OUTPUT_FOLDER}${MAIN_DOMAIN}.key" -out "${CERT_OUTPUT_FOLDER}${MAIN_DOMAIN}.csr" -subj "/CN=$MAIN_DOMAIN"

generateExtensionFile > "${OUTPUT_FOLDER}v3.ext"

if ! output=$(openssl x509 -req -in "${CERT_OUTPUT_FOLDER}${MAIN_DOMAIN}.csr" -CA "${OUTPUT_FOLDER}ca.pem" -CAkey "${OUTPUT_FOLDER}ca.key" -CAcreateserial -passin "pass:$PASS" -out "${CERT_OUTPUT_FOLDER}${MAIN_DOMAIN}.crt" -days "$DAYS" -extensions EXT -extfile "${OUTPUT_FOLDER}v3.ext"); then
    echo $output
    red "Could not generate certificate for domain \"${MAIN_DOMAIN}\"."
    rm -f "${CERT_OUTPUT_FOLDER}${MAIN_DOMAIN}.crt" # Remove failed crt
    rm -f "${CERT_OUTPUT_FOLDER}${MAIN_DOMAIN}.key" # Remove failed key
    cleanup
    exit 1;
fi

green "Cleaning up files"
cleanup
green "Successfully generated certificate for domain \"${MAIN_DOMAIN}\"."