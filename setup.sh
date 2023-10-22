#!/bin/bash

# -----------------------------------------------------------------------------
# Doc:
# This script setup the Lab:
#   - Generating all the required symbolic link
# -----------------------------------------------------------------------------

# Paths
TRASH='/dev/null'
DIR_ENVVARS='Configs/sh'
FILE_ENVVARS="${DIR_ENVVARS}/envvars.sh"
# -----------------------------------------------------------------------------
# Vars:
# Genarete a file that contain all environment variables
# -----------------------------------------------------------------------------
LAB_ROOT=$(pwd .)
LAB_NAME=$(echo "$LAB_ROOT" | sed -E 's#.+/(.*)$#\1#g')
S='\n'
ALL_VAR="#!/bin/bash${S}
LAB_ROOT=${LAB_ROOT}
LAB_NAME=${LAB_NAME}"
(ls "$DIR_ENVVARS" > "$TRASH" 2>&1 || mkdir "$DIR_ENVVARS") && echo "$ALL_VAR" > $FILE_ENVVARS
# -----------------------------------------------------------------------------
# Generate config files
# -----------------------------------------------------------------------------
DIR_APACHE_VH='Servers/Apache/Stage/Shared/sites-available'
DIRS_APP_VH=('Applications/IsraelMeiresonne/Stage/Services/Server/Apache/sites-available'
             'Applications/MeimBox/Stage/Services/Server/Apache/sites-available'
             'Applications/LamaChat/Stage/Services/Server/Apache/sites-available')
( (ls "${DIR_APACHE_VH}" | grep '' && rm "${DIR_APACHE_VH}/"*) \
|| (ls "${DIR_APACHE_VH}" || mkdir "${DIR_APACHE_VH}") ) > "$TRASH" 2>&1
for DIR_APP_VH in "${DIRS_APP_VH[@]}"
do
  (ls "${DIR_APP_VH}" | grep '') > "$TRASH" 2>&1  \
  && cp "${DIR_APP_VH}/"* "${DIR_APACHE_VH}/" || printf ''
done
