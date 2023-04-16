#!/usr/bin/env bash

DOMAIN=$1
CA_NAME=$2
PASS=$3
DAYS=${4:-3650}
OUTPUT_FOLDER="output/$CA_NAME/"

mkdir -p "$OUTPUT_FOLDER"

if [[ ! -f "ca.pem" ]]; then
    if [[ ! -f "ca.key" ]]; then
        openssl genrsa -aes256 -out "${OUTPUT_FOLDER}ca.key" 4096 -passout "pass:$PASS"
    fi
    openssl req -x509 -new -nodes -key "${OUTPUT_FOLDER}ca.key" -days "$DAYS" -passin "pass:$PASS" -out "${OUTPUT_FOLDER}ca.pem" -subj "/CN=$CA_NAME"
fi

openssl req -nodes -newkey rsa:2048 -keyout "${OUTPUT_FOLDER}${DOMAIN}.key" -out "${OUTPUT_FOLDER}${DOMAIN}.csr" -subj "/CN=$DOMAIN"

echo "# v3.ext
[EXT]
subjectAltName=DNS.0:*.ichiva.local" > "${OUTPUT_FOLDER}v3.ext"

openssl x509 -req -in "${OUTPUT_FOLDER}${DOMAIN}.csr" -CA "${OUTPUT_FOLDER}ca.pem" -CAkey "${OUTPUT_FOLDER}ca.key" -CAcreateserial -passin "pass:$PASS" -out "${OUTPUT_FOLDER}${DOMAIN}.crt" -days "$DAYS" -extensions EXT -extfile "${OUTPUT_FOLDER}v3.ext"

#rm -f "${OUTPUT_FOLDER}v3.ext" "${OUTPUT_FOLDER}ca.srl" "${OUTPUT_FOLDER}${DOMAIN}.csr"