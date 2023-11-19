#!/bin/bash

# -----------------------------------------------------------------------------
# This script help Dockerfile to set up the image
# Inputs:
#   - DIR_DOCUMENT_ROOT:
#       Absolut path of the directory served by the server (i.e.: '/var/www')
#   - DIR_CERTBOT_SCRIPT:
#       Absolut path to script used to manage Certbot
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
CURRENT_SCRIPT=$(getelx "$0" -1)
# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------
DIR_DOCUMENT_ROOT=$1
DIR_CERTBOT_SCRIPT=$2
if test -z "$DIR_DOCUMENT_ROOT" || test ! -d "$DIR_DOCUMENT_ROOT" ; then
    echo "$(error_prefix $LINENO) DIR_DOCUMENT_ROOT don't exist as directory: DIR_DOCUMENT_ROOT='$DIR_DOCUMENT_ROOT'"
    exit 1
fi
if test -z "$DIR_CERTBOT_SCRIPT" || test ! -d "$DIR_CERTBOT_SCRIPT" ; then
    echo "$(error_prefix $LINENO) DIR_CERTBOT_SCRIPT don't exist as directory: DIR_CERTBOT_SCRIPT='$DIR_CERTBOT_SCRIPT'"
    exit 1
fi
# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------
DIR_CERTBOT_CRON='/etc/cron.d/certbot'
DIR_ROOT='/root'
FILE_BASHRC="${DIR_ROOT}/.bashrc"
FILE_APACHE_PHP_INI='/etc/php/7.4/apache2/php.ini'
FILE_CERTBOT_SCRIPT='certbot.sh'
FILE_CERTBOT_DEPLOY='deploy.sh'
# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
TRASH='/dev/null'
SEARCH="&& (certbot.*)$"
NEW_CMD="\
\&\& cd ${DIR_CERTBOT_SCRIPT} \
\&\& bash $FILE_CERTBOT_SCRIPT '${DIR_DOCUMENT_ROOT}' gen-hook \
\&\& \1 --deploy-hook './$FILE_CERTBOT_DEPLOY' \
\&\& bash $FILE_CERTBOT_SCRIPT '${DIR_DOCUMENT_ROOT}' delete-hook"
BOOT_START_CRON="
# Start cron if not running
(systemctl status cron | grep -E 'Active.*running' > '$TRASH') \
|| systemctl -q start cron || echo 'Fail to start cron service'"
BOOT_START_APACHE="
# Start Apache server if not running
(systemctl status apache2 | grep -E 'Active.*running' > '$TRASH') \
|| systemctl -q start apache2 || echo 'Fail to start apache2 service'"
PHP_SED="\
s#;extension=pdo_mysql#extension=pdo_mysql#;
s#display_errors = On#display_errors = Off#"
# -----------------------------------------------------------------------------
# Execution
# -----------------------------------------------------------------------------
# - Edit cron task that renew certificates
sed -Ei "s#${SEARCH}#${NEW_CMD}#" "$DIR_CERTBOT_CRON"
# - Append instruction to start Cron daemon
echo "$BOOT_START_CRON" >> $FILE_BASHRC
# - Append instruction to start Apache server
echo "$BOOT_START_APACHE" >> $FILE_BASHRC
# - Edit PHP confit:
#   1. Activate MySQL PDO
#   2. Turn Off display of errors for users
sed -i "$PHP_SED" "$FILE_APACHE_PHP_INI"
