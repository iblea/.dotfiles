#!/bin/bash

if grep -q "ERROR: grep result is empty" <<< "$@"; then
    exit 2
elif grep -q "ERROR: cannot find" <<< "$@"; then
    exit 1
fi

if [ -n "$(command -v code)" ]; then
    code --goto "$@"
    exit 0
fi

if [ -n "$(command -v code-insiders)" ]; then
    code-insiders --goto "$@"
    exit 0
fi

if [ -n "$(command -v cursor)" ]; then
    cursor --goto "$@"
    exit 0
fi


fileinfo="$@"
# echo "fileinfo : $fileinfo"
filename="${fileinfo%:*}"
line="${fileinfo##*:}"

# echo "filename : $filename"
# echo "line : $line"
# vim +$line "$filename" -c 'normal zt'

echo "$filename" | xargs -I{} -o vim {} +${line}

# filename
# vim "$filename"