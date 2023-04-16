#! /usr/bin/env bash

DOMAIN=$1
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
    rm -f "${OUTPUT_FOLDER}v3.ext" "${OUTPUT_FOLDER}ca.srl" "${CERT_OUTPUT_FOLDER}${DOMAIN}.csr"
}

mkdir -p "$OUTPUT_FOLDER"
mkdir -p "$CERT_OUTPUT_FOLDER"

if [[ ! -f "${OUTPUT_FOLDER}ca.pem" ]]; then
    if [[ ! -f "${OUTPUT_FOLDER}ca.key" ]]; then
        openssl genrsa -aes256 -out "${OUTPUT_FOLDER}ca.key" 4096 -passout "pass:$PASS"
    fi
    openssl req -x509 -new -nodes -key "${OUTPUT_FOLDER}ca.key" -days "$DAYS" -passin "pass:$PASS" -out "${OUTPUT_FOLDER}ca.pem" -subj "/CN=$CA_NAME"
fi

if [[ -f "${OUTPUT_FOLDER}certificates/${DOMAIN}.key" ]] || [[ -f "${CERT_OUTPUT_FOLDER}${DOMAIN}.crt" ]]; then
    echo "Certificate for domain \"${DOMAIN}\" already exists."
    exit 1;
fi

openssl req -nodes -newkey rsa:2048 -keyout "${CERT_OUTPUT_FOLDER}${DOMAIN}.key" -out "${CERT_OUTPUT_FOLDER}${DOMAIN}.csr" -subj "/CN=$DOMAIN"

echo "# v3.ext
[EXT]
subjectAltName=DNS.0:$DOMAIN" > "${OUTPUT_FOLDER}v3.ext"

if ! output=$(openssl x509 -req -in "${CERT_OUTPUT_FOLDER}${DOMAIN}.csr" -CA "${OUTPUT_FOLDER}ca.pem" -CAkey "${OUTPUT_FOLDER}ca.key" -CAcreateserial -passin "pass:$PASS" -out "${CERT_OUTPUT_FOLDER}${DOMAIN}.crt" -days "$DAYS" -extensions EXT -extfile "${OUTPUT_FOLDER}v3.ext"); then
    echo $output
    red "Could not generate certificate for domain \"${DOMAIN}\"."
    rm -f "${CERT_OUTPUT_FOLDER}${DOMAIN}.crt" # Remove failed crt
    rm -f "${CERT_OUTPUT_FOLDER}${DOMAIN}.key" # Remove failed key
    cleanup
    exit 1;
fi

green "Cleaning up files"
cleanup
green "Successfully generated certificate for domain \"${DOMAIN}\"."