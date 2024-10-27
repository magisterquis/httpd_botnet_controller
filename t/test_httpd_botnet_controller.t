#!/bin/ksh
#
# test_httpd_botnet_controller.t
# Make sure the botnet controller works
# By J. Stuart McMurray
# Created 20241027
# Last Modified 20241027

# Grab the testing library
. t/tap.sh/tap.sh

# Testing directories
TMPDIR=$(mktemp -td $(basename $0).XXXXXX)
if [[ -z "$TMPDIR" ]]; then
        echo "Failed to make temporary directory, bailing" >&2
        exit 1;
fi
ID=kittens
export TASKING_DIR=$TMPDIR/tasking
export HTTPDLOGFILE=$TMPDIR/log
export LAST_DIR=$TMPDIR/bots
export TAILFLAGS="-n +0"
CHECKIN_PATH=httpd_botnet_controller
trap 'rm -rf "$TMPDIR"' EXIT
if ! mkdir -p "$TASKING_DIR" "$LAST_DIR"; then
        echo "Failed to make needed directories, bailing" >&2
        exit 2
fi

# Log to use for testing
LOG='
example.com 127.0.0.1 - - [27/Oct/2024:19:07:33 +0100] "GET /httpd_botnet_controller/kittens HTTP/1.1" 200 50
'
echo "$LOG" >$HTTPDLOGFILE
tap_ok $? "Wrote httpd log"

# Test a simple check-in
! [[ -f "$LAST_DIR/$ID" ]]
tap_ok $? "Simple check-in not checked in"
GOT=$(./httpd_botnet_controller.sh 2>&1 | cut -f 2- -d -)
tap_ok $? "Simple log read"
WANT=" kittens - Check-in"
tap_cmp "$GOT" "$WANT" "Simple check-in logged"
[[ -f "$LAST_DIR/$ID" ]]
tap_ok $? "Simple check-in checked in"
rm "$LAST_DIR/$ID"
tap_ok $? "Removed simple check-in file"

# Test a check-in with tasking
TASK='foo'
echo "$TASK" >"$TASKING_DIR/$ID"
tap_ok $? "Wrote tasked tasking file"
! [[ -f "$LAST_DIR/$ID" ]]
tap_ok $? "Tasked check-in already checked in"
GOT=$(./httpd_botnet_controller.sh 2>&1 | cut -f 2- -d -)
tap_ok $? "Tasked log read"
WANT=" kittens - Check-in
 kittens - Sent $TASKING_DIR/$ID"
tap_cmp "$GOT" "$WANT" "Tasked check-in logged"
[[ -f "$LAST_DIR/$ID" ]]
tap_ok $? "Simple check-in checked in"
rm "$LAST_DIR/$ID"
tap_ok $? "Removed simple check-in file"
! [[ -f "$TASKING_DIR/$ID" ]]
tap_ok $? "Tasking removed"

# Test a check-in updates timestamps
BEFORE="$LAST_DIR/$ID.before"
touch -t 199912312359 "$BEFORE"
tap_ok $? "Created check-in before file"
[[ -f "$BEFORE" ]]
tap_ok $? "Check-in before file exists"
GOT=$(./httpd_botnet_controller.sh 2>&1 | cut -f 2- -d -)
tap_ok $? "Check-in log read"
WANT=" kittens - Check-in"
tap_cmp "$GOT" "$WANT" "Check-in logged"
[[ -f "$LAST_DIR/$ID" ]]
tap_ok $? "Check-in checked in"
[[ $BEFORE -ot "$LAST_DIR/$ID" ]]
tap_ok $? "Check-in file newer than before file"
rm "$LAST_DIR/$ID"
tap_ok $? "Removed check-in file"

tap_end
# vim: ft=sh
