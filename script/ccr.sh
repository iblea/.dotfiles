#!/bin/bash

PORT=0
PROGRAM_NAME="stopped_program_regular_expreess"
PROGRAM_PATH="path/to/server/path"
START_SCRIPT="server_start_script.sh"

function kill_with_signal() {
	local SIGNAL="$1"
	local max_count=5
	local shutdown_count=0
	while [ $shutdown_count -lt $max_count ]; do
		pid=$(pgrep -f "${PROGRAM_NAME}" | grep -v $$)
		if [ -z "$pid" ]; then
			return 0
		fi
		echo "$pid" | xargs kill -${SIGNAL}
		sleep 0.5
		echo "$pid" | xargs -I{} echo "stopped $PROGRAM_NAME pid: {}"
		((shutdown_count++))
	done
	return 1
}

kill_with_signal 15

cd "$PROGRAM_PATH"

./"$START_SCRIPT"

