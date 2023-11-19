#!/bin/bash

# -----------------------------------------------------------------------------
# Parameters:
#   1. Document:
#       Directory that the server serve (i.e.: DOCUMENT_ROOT=/var/www)
#       Stop script if empty
#   2. Excution mode:
#       1. '(gen|renew|revok|delete)-stage'
#       2. '(gen|renew|revok|delete)-prod'
#       3. '(gen|delete)-hook'
#       3. 'debug'
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
error_prefix() {
    error_line=$1
    echo "$CURRENT_SCRIPT: ${error_line}:"
}
getelx() {
    # -------------------------------------------------------------------------
    # To get element from a given list at a given position
    # Parameters:
    #   - LIST: list of element separated by a separator
    #       - If the list start with the separator then the starting separator
    #         is ignored
    #   - INDEX: Position of the element to get
    #       - Position interval [N,0[ and ]0,N] (N: number of element)
    #         Zero is excluded from index
    #   - SEPARATOR (optional): The separator used to split list into elements
    #       - If not provided its default value if a slash '/'
    # Examples:
    #   - LIST='/A/B/C/D/E', INDEX=1 >>> A
    #   - LIST='/A/B/C/D/E', INDEX=2 >>> B
    # -------------------------------------------------------------------------
    LIST=$1
    INDEX=$2
    SEPARATOR=$3
    # -------------------------------------------------------------------------
    # Constants
    # -------------------------------------------------------------------------
    TRASH='/dev/null'
    DEFAULT_SEPARATOR='/'
    # -------------------------------------------------------------------------
    # Check Inputs
    # -------------------------------------------------------------------------
    if [[ -z "${LIST}" ]]; then
        echo "$(error_prefix $LINENO) LIST can't be empty: LIST='$LIST'"
        exit 26
    fi
    test $INDEX -eq $INDEX
    IS_INT="$?"
    if (( $IS_INT != 0 )); then
        echo "$(error_prefix $LINENO) INDEX must be of type integer: INDEX='$INDEX'"
        exit 32
    fi
    if [ $INDEX -eq 0 ] ; then
        echo "$(error_prefix $LINENO) INDEX can't be equal to zero (0): INDEX='$INDEX'"
        exit 36
    fi
    # -------------------------------------------------------------------------
    # Set Variables
    # -------------------------------------------------------------------------
    if [[ -z "${SEPARATOR}" ]]; then
        SEPARATOR=$DEFAULT_SEPARATOR
    fi
    NEG_INDEX=$((INDEX * -1))
    CLEANED=$(echo "$LIST" | sed -E "s#${SEPARATOR}+#${SEPARATOR}#g; s#^${SEPARATOR}##g")
    CLEANED_LINES=$(echo "$CLEANED" | tr "${SEPARATOR}" '\n')
    ELEMENT_X=''
    # -------------------------------------------------------------------------
    # Get element
    # -------------------------------------------------------------------------
    if (! (echo "$CLEANED_LINES" | nl | grep -E "$(echo $INDEX | sed -E 's#\-##g')") > "$TRASH" 2>&1) ; then
        NLINE=$(echo "$CLEANED_LINES" | wc -l | sed 's# *##g')
        echo "$(error_prefix $LINENO) INDEX must be in interval [-$NLINE,0[ and ]0,$NLINE]: INDEX='$INDEX'"
        exit 1
    fi
    if test "$INDEX" -ge 0; then
        ELEMENT_X=$(echo "$CLEANED_LINES" | head -n "$INDEX" | tail -n 1)
    else
        ELEMENT_X=$(echo "$CLEANED_LINES" | tail -n "$NEG_INDEX" | head -n 1)
    fi
    echo "$ELEMENT_X"
}
# -----------------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------------
DOCUMENT_ROOT=$1
EXEC_MODE=$2
# -----------------------------------------------------------------------------
# Check Inputs
# -----------------------------------------------------------------------------
CURRENT_SCRIPT=$(getelx "$0" -1)
if [ ! -f "./$CURRENT_SCRIPT" ]; then
    echo "$(error_prefix $LINENO) Must be in the same directory than script '${CURRENT_SCRIPT}'"
    exit 1
fi
if [[ -z "${DOCUMENT_ROOT}" ]]; then
    echo "$(error_prefix $LINENO) DOCUMENT_ROOT can't be empty"
    exit 1
fi
if [[ -z "${EXEC_MODE}" ]]; then
    echo "$(error_prefix $LINENO) EXEC_MODE can't be empty"
    exit 1
fi
# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
TRASH='/dev/null'
STAGES=('gen-stage' 'renew-stage' 'revok-stage' 'delete-stage')
PRODS=('gen-prod' 'renew-prod' 'revok-prod' 'delete-prod')
HOOKS=('gen-hook' 'delete-hook')
DEBUG='debug'
FILE_AUTHENTICATOR='authenticator.sh'
FILE_CLEANUP='cleanup.sh'
FILE_DEPLOY='deploy.sh'
DIRS_CHALLENGE='.well-known/acme-challenge'
FILE_INPUT='input.txt'
if ! [ -f "$FILE_INPUT" ]; then
    echo "$(error_prefix $LINENO) File '$FILE_INPUT' must exist in the directory"
    exit 124
fi
# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
DOMAINS=$(cat "./$FILE_INPUT" | grep 'DOMAINS' | sed -E 's#.*=(.*)$#\1#; s#^ +##g; s# +$##g')
FIRST_DIR_CHALLENGE=$(getelx "$DIRS_CHALLENGE" 1)
# -----------------------------------------------------------------------------
# Manage Hooks
# -----------------------------------------------------------------------------
if [[ "${EXEC_MODE}" == "${HOOKS[1]}" ]]; then
    test -f "$FILE_AUTHENTICATOR" && rm "$FILE_AUTHENTICATOR"
    test -f "$FILE_CLEANUP" && rm "$FILE_CLEANUP"
    test -f "$FILE_DEPLOY" && rm "$FILE_DEPLOY"
fi
if [[ "${EXEC_MODE}" == "${HOOKS[0]}" ]]; then
    # - Authenticator
    echo \
        "#!/bin/bash

WEBROOT=\"${DOCUMENT_ROOT}/\${CERTBOT_DOMAIN}\"
DIR_CERTBOT_TOKEN=\"\${WEBROOT}/${DIRS_CHALLENGE}\"
mkdir -p \"\$DIR_CERTBOT_TOKEN\"
echo \"\$CERTBOT_VALIDATION\" > \"\${DIR_CERTBOT_TOKEN}/\$CERTBOT_TOKEN\"\
" > "$FILE_AUTHENTICATOR"
    # - Cleanup
    echo \
        "#!/bin/bash

WEBROOT=\"${DOCUMENT_ROOT}/\${CERTBOT_DOMAIN}\"
rm -fr \"\${WEBROOT}/${FIRST_DIR_CHALLENGE}\"\
" > "$FILE_CLEANUP"
    # - Deploy
    echo \
        "#!/bin/bash

systemctl reload apache2" > "$FILE_DEPLOY"
    # - Make them executable
    chmod 711 "$FILE_AUTHENTICATOR" "$FILE_CLEANUP" "$FILE_DEPLOY"
fi
# -----------------------------------------------------------------------------
# Get Certificate
# -----------------------------------------------------------------------------
if [[ "${EXEC_MODE}" == "${PRODS[0]}" ]]; then
    certbot certonly \
        --manual --preferred-challenges=http \
        --manual-auth-hook "./$FILE_AUTHENTICATOR" \
        --manual-cleanup-hook "./$FILE_CLEANUP" \
        -d "$DOMAINS"
fi
if [[ "${EXEC_MODE}" == "${STAGES[0]}" ]]; then
    certbot certonly --staging \
        --manual --preferred-challenges=http \
        --manual-auth-hook "$FILE_AUTHENTICATOR" \
        --manual-cleanup-hook "$FILE_CLEANUP" \
        -d "$DOMAINS"
fi
# -----------------------------------------------------------------------------
# Debug
# -----------------------------------------------------------------------------
if [[ "${EXEC_MODE}" == "$DEBUG" ]]; then
    echo "\
    DOCUMENT_ROOT =         ${DOCUMENT_ROOT}
    EXEC_MODE =             ${EXEC_MODE}
    CURRENT_SCRIPT =        ${CURRENT_SCRIPT}
    TRASH =                 ${TRASH}
    STAGES =                ${STAGES[*]}
    PRODS =                 ${PRODS[*]}
    HOOKS =                 ${HOOKS[*]}
    DEBUG =                 ${DEBUG}
    FILE_AUTHENTICATOR =    ${FILE_AUTHENTICATOR}
    FILE_CLEANUP =          ${FILE_CLEANUP}
    FILE_DEPLOY =           ${FILE_DEPLOY}
    DIRS_CHALLENGE =        ${DIRS_CHALLENGE}
    FILE_INPUT =            ${FILE_INPUT}
    DOMAINS =               ${DOMAINS}
    FIRST_DIR_CHALLENGE =   ${FIRST_DIR_CHALLENGE}
    OPTION_STAGE =          ${OPTION_STAGE}\
    "
fi
# # -----------------------------------------------------------------------------
# # Test force renewal
# # -----------------------------------------------------------------------------
# cd /root/scripts/letsencrypt \
# && bash certbot.sh '/var/www' gen-hook \
# && certbot -q renew --staging --force-renewal --break-my-certs \
#     --deploy-hook "echo 'Deploy succeed' >> /root/scripts/letsencrypt/deploy-hook.txt" \
# && bash certbot.sh '/var/www' delete-hook
# -----------------------------------------------------------------------------
# Test revoke
# -----------------------------------------------------------------------------
# certbot revoke --staging --cert-name example.com
