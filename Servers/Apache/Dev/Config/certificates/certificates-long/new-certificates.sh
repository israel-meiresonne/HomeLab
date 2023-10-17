#!/bin/bash

TRASH='/dev/null'
DIR_INPUTS='./input'
DIR_STACK='./stack'
DIR_CERTIFICATES='./certificates'
FILE_CA_KEY="${DIR_STACK}/rootCA.key"
FILE_PUBLIC_CA_KEY="${DIR_STACK}/rootCA.pem"
FILE_INPUT_SERVER_CERTIFICATE="${DIR_INPUTS}/server.csr.cnf"
FILE_SERVER_KEY="${DIR_CERTIFICATES}/server.key"
FILE_SERVER_CERTIFICATE_REQUEST="${DIR_STACK}/server.csr"
FILE_SERVER_CERTIFICATE="${DIR_CERTIFICATES}/server.crt"
FILE_INPUT_X509_V3="${DIR_INPUTS}/v3.ext"

(mkdir "$DIR_INPUTS" "$DIR_STACK" "$DIR_CERTIFICATES") 2> "$TRASH"
openssl genrsa -des3 -out "$FILE_CA_KEY" 2048
# SSL Certificate for Computer
openssl req -x509 -new -nodes -key "$FILE_CA_KEY" -sha256 -days 1024 -out "$FILE_PUBLIC_CA_KEY"
echo "
[req]
default_bits=           2048
prompt=                 no
default_md=             sha256
distinguished_name=     dn
[dn]
C=                      US
ST=                     ExampleState
L=                      ExampleCity
O=                      Organization
OU=                     OrganizationUnit
emailAddress=           example@mail.com
CN=                     localhost" > "$FILE_INPUT_SERVER_CERTIFICATE"

echo "
authorityKeyIdentifier= keyid,issuer
basicConstraints=       CA:FALSE
keyUsage =              digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName =        @alt_names
[alt_names]
DNS.1 =                 localhost" > "$FILE_INPUT_X509_V3"

openssl req -new -sha256 -nodes -out "$FILE_SERVER_CERTIFICATE_REQUEST" \
-newkey rsa:2048 -keyout "$FILE_SERVER_KEY" \
-config ./"$FILE_INPUT_SERVER_CERTIFICATE"

openssl x509 -req -in "$FILE_SERVER_CERTIFICATE_REQUEST" -CA "$FILE_PUBLIC_CA_KEY" \
-CAkey "$FILE_CA_KEY" -CAcreateserial -out "$FILE_SERVER_CERTIFICATE" \
-days 800 -sha256 -extfile "$FILE_INPUT_X509_V3"
