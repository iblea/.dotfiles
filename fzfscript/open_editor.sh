#!/bin/bash

if grep -q "ERROR: grep result is empty" <<< "$@"; then
    exit 2
elif grep -q "ERROR: cannot find" <<< "$@"; then
    exit 1
fi

PATH_BACKUP="$PATH"
code_path="$(which code)"
export PATH=$( echo "$PATH" | sed -e "s|$HOME/\.dotfiles/\.bin:\?||" )
if [ -n "$(command -v code)" ] || [ -n "$(command -v cursor)" ]; then
	"$code_path" --goto $@
	exit 0
fi
# if [ -n "$(command -v code)" ]; then
#     code --goto "$@"
#     exit 0
# fi
# 
# if [ -n "$(command -v code-insiders)" ]; then
#     code-insiders --goto "$@"
#     exit 0
# fi
# 
# if [ -n "$(command -v cursor)" ]; then
#     cursor --goto "$@"
#     exit 0
# fi

fileinfo="$@"
# echo "fileinfo : $fileinfo"
filename="${fileinfo%:*}"
line="${fileinfo##*:}"

# echo "filename : $filename"
# echo "line : $line"
# vim +$line "$filename" -c 'normal zt'

clear
echo "Do you want to open file with vi?"
echo "filepath: $filename"
# echo "$(pwd)"
# real_filename=$(echo "$filename" | sed -e "s|$(pwd)/||")
# echo "real_filename: $real_filename"

read -sn 1 key < /dev/tty

if [[ -z "$key" ]] || [[ "$key" == $'\n' ]] || [[ "$key" == $'\r' ]]; then
    echo "$filename" | xargs -I{} -o vim {} +${line}
fi


# filename
# vim "$filename"
