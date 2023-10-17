#!/bin/bash

# -----------------------------------------------------------------------------
# Doc:
# This script setup the Lab:
#   - Generating all the required symbolic link
# -----------------------------------------------------------------------------

# Paths
TRASH='/dev/null'
PATH_SETUP_ENVVARS='Configs/sh/setup_envvars.sh'
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
