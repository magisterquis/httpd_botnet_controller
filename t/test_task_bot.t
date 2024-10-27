#!/bin/ksh
#
# test_task_bot.t
# Make sure tasking works
# By J. Stuart McMurray
# Created 20241027
# Last Modified 20241027

# Grab the testing library
. t/tap.sh/tap.sh

# Temporary tasking directory
export TASKING_DIR=$(mktemp -td $(basename $0).XXXXXX)
if [[ -z "$TASKING_DIR" ]]; then
        echo "Failed to make temporary directory, bailing" >&2
        exit 1;
fi
trap 'rm -rf "$TASKING_DIR"' EXIT

# ID and task file
ID="kittens"
TASKFILE=$TASKING_DIR/$ID

# Check creating a task with argv
TASK="uname -a"
./task_bot.sh "$ID" $TASK >/dev/null
tap_ok $? "Call with task from argv"
GOT="$(cat <$TASKFILE)"
tap_ok $? "Read tasking after task from argv"
tap_cmp "$GOT" "$TASK" "Content of task from argv"
rm "$TASKFILE"
tap_ok $? "Remove argv task file"

# Check creating a task with stdin
TASK=$(cat <<'_eof'
ps awwwfux
uname -a
id
_eof
)
echo "$TASK" | ./task_bot.sh "$ID" >/dev/null
tap_ok $? "Call with task from stdin"
GOT="$(cat <$TASKFILE)"
tap_ok $? "Read tasking after task from stdin"
tap_cmp "$GOT" "$TASK" "Content of task from stdin"
rm "$TASKFILE"
tap_ok $? "Remove stdin task file"

# Check appending tasking
TASK1="foo"
GOT=$(./task_bot.sh "$ID" "$TASK1" 2>&1)
tap_ok $? "Call with first task line"
WANT="Put tasking in $TASKFILE"
tap_cmp "$GOT" "$WANT" "First call output"
TASK2="bar"
GOT=$(./task_bot.sh "$ID" "$TASK2" 2>&1)
tap_ok $? "Call with second task line"
WANT="Temporarily renaming existing $TASKFILE as $TASKFILE.tmp
Put tasking in $TASKFILE"
tap_cmp "$GOT" "$WANT" "Second call output"
WANT="$TASK1
$TASK2"
GOT="$(cat <$TASKFILE)"
tap_ok $? "Read tasking after two calls"
tap_cmp "$GOT" "$WANT" "Content of task after two calls"
rm "$TASKFILE"
tap_ok $? "Remove two-call task file"

# Make sure we bail if a temporary file exists
touch "$TASKFILE.tmp"
tap_ok $? "Create temporary taskfile"
WANT=2
set +e
GOT=$(./task_bot.sh "$ID" "dummy" 2>&1)
tap_cmp "$?" "$WANT" "Call with existing temporary taskfile"
set -e
WANT="Temporary file $TASKFILE.tmp already exists, bailing"
tap_cmp "$GOT" "$WANT" "Output from call with existing temporary taskfile"

tap_end
# vim: ft=sh
