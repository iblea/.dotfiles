#!/bin/bash

# automator process name : pdf_preview.app

REALPATH_BIN=/opt/homebrew/opt/coreutils/libexec/gnubin/realpath
LSOF_BIN=/usr/sbin/lsof
GREP_PATH=/opt/homebrew/opt/grep/libexec/gnubin/grep
abspath=$($REALPATH_BIN -e "$@")

# logging
# echo "path : '$abspath')" >> ~/automator.log


res=$($LSOF_BIN | $GREP_PATH "^Preview" | grep "$abspath")

# if res is not exist, already open file
if [ "$res" != "" ]; then
    # open new window (open -na)
    open -na /System/Applications/Preview.app "$@"
else
    open -a /System/Applications/Preview.app "$@"
fi
