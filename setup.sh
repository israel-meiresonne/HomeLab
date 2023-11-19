#!/bin/bash

# -----------------------------------------------------------------------------
# Doc:
# This script setup the Lab:
#   - Generating all the required symbolic link
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
error_prefix() {
  error_line=$1
  echo "$CURRENT_SCRIPT: ${error_line}:"
}

get_last_file() {
  FILE_PATH=$1
  if [[ -z "${FILE_PATH}" ]]; then
    echo "$(error_prefix $LINENO) FILE_PATH can't be empty: FILE_PATH='$FILE_PATH'"
    exit 1
  fi
  echo "$FILE_PATH" | sed -E 's#.+/(.*)$#\1#g'
}

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------
TRASH='/dev/null'
DIR_ENVVARS='Configs/sh'
FILE_ENVVARS="${DIR_ENVVARS}/envvars.sh"

# -----------------------------------------------------------------------------
# Genarete a file that contain all environment variables
# -----------------------------------------------------------------------------
LAB_ROOT=$(pwd .)
LAB_NAME=$(get_last_file "$LAB_ROOT")
S='\n'
ALL_VAR="#!/bin/bash${S}
LAB_ROOT=${LAB_ROOT}
LAB_NAME=${LAB_NAME}"
(ls "$DIR_ENVVARS" >"$TRASH" 2>&1 || mkdir "$DIR_ENVVARS") && echo "$ALL_VAR" >$FILE_ENVVARS
# -----------------------------------------------------------------------------
# Generate config files
# -----------------------------------------------------------------------------
MASK_LOCK=551
MASK_UNLOCK=751
# - Load config for Apache's Virtual Host
DIR_APACHE_VH='Servers/Apache/Stage/Shared/var/shared/sites-available'
DIRS_APP_VH=('Applications/IsraelMeiresonne/Stage/Services/Server/Apache/sites-available'
  'Applications/MeimBox/Stage/Services/Server/Apache/sites-available'
  'Applications/LamaChat/Stage/Services/Server/Apache/sites-available')
if test -d "$DIR_APACHE_VH" && (ls "$DIR_APACHE_VH" | grep '' >"$TRASH" 2>&1); then
  # Directory Not empty
  chmod "$MASK_UNLOCK" "${DIR_APACHE_VH}/"* &&
    rm "${DIR_APACHE_VH}/"*
fi
for DIR_APP_VH in "${DIRS_APP_VH[@]}"; do
  (ls "${DIR_APP_VH}" | grep '') >"$TRASH" 2>&1 &&
    cp "${DIR_APP_VH}/"* "${DIR_APACHE_VH}/" || printf ''
done
(ls "$DIR_APACHE_VH" | grep '') >"$TRASH" && chmod "$MASK_LOCK" "${DIR_APACHE_VH}/"*
# - Distribute Certbot to Servers
FILE_CERTBOT="${LAB_ROOT}/Configs/letsencrypt/certbot.sh"
FILE_CERTBOT_NAME=$(get_last_file "$FILE_CERTBOT")
DIRS_SERVER_CERTBOT=("${LAB_ROOT}/Servers/Apache/Stage/Config/root/scripts/letsencrypt")
for DIR_SERVER_CERTBOT in "${DIRS_SERVER_CERTBOT[@]}"; do
  FILE_COPY_CERTBOT="${DIR_SERVER_CERTBOT}/${FILE_CERTBOT_NAME}"
  (test -d "$DIR_SERVER_CERTBOT" || mkdir -p "$DIR_SERVER_CERTBOT") &&
    (test -f "$FILE_COPY_CERTBOT" && chmod "$MASK_UNLOCK" "$FILE_COPY_CERTBOT" ||
      test 1 = 1) &&
    cp "${FILE_CERTBOT}" "$FILE_COPY_CERTBOT" &&
    chmod "$MASK_LOCK" "$FILE_COPY_CERTBOT"
done
# - Load 'Config/' to Shared Volume
DIR_ROOT_SCRIPT="${LAB_ROOT}/Servers/Apache/Stage/Config/root/scripts"
DIR_SHARED_ROOT_SCRIPT="${LAB_ROOT}/Servers/Apache/Stage/Shared/root/scripts"
(test -d "$DIR_SHARED_ROOT_SCRIPT" || mkdir -p "$DIR_SHARED_ROOT_SCRIPT") &&
  cp -fR "${DIR_ROOT_SCRIPT}/"* "$DIR_SHARED_ROOT_SCRIPT"
# # ----------------------------------------------------------------------------❌
# echo "Hello" ❌
# # ----------------------------------------------------------------------------❌
