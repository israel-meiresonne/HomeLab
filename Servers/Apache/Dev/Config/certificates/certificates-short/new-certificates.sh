#!/bin/bash

# -----------------------------------------------------------------------------
# Script to generate SSL certificates files
# -----------------------------------------------------------------------------

# Inputs
CERTIFICATE_NAME=$(echo "$1" | tr '[A-Z] ' '[a-z]-')
if [ "$CERTIFICATE_NAME" == "" ] ;
then
    echo "Parameter 'CERTIFICATE_NAME' can't be empty!" && exit 1
fi
# Path
TRASH='/dev/null'
DIR_OUTPUT='./certificates'
FILE_SSL_PROMPT_INPUT='./inputs.txt'
FILE_CERTIFICATE="${DIR_OUTPUT}/${CERTIFICATE_NAME}-certificate.crt"
FILE_KEY="${DIR_OUTPUT}/${CERTIFICATE_NAME}.key"
# Vars
# Main
ls "$DIR_OUTPUT" > "$TRASH" 2>&1 || mkdir "$DIR_OUTPUT"
cat "$FILE_SSL_PROMPT_INPUT" | sed -E 's#.+=(.*)#\1#g; s#^ +##g; s# +$##g' \
| openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \
-out "$FILE_CERTIFICATE" -keyout "$FILE_KEY"
