#!/bin/bash

if ! grep -q ":" <<< "$1"; then
    echo "Wrong input"
    exit 1
fi

if ( grep -q "ERROR: grep result is empty" <<< "$@" ); then
    echo "1" >> /tmp/test.txt
    exit 1
elif ( grep -q "ERROR: cannot find" <<< "$@" ); then
    echo "2" >> /tmp/test.txt
    exit 1
fi

filename=$(echo "$1" | awk -F ':' '{print $1}')
line=$(echo "$1" | awk -F ':' '{print $2}')

file_end_line=$(wc -l "$filename" | awk '{print $1}')

# (stty height) - 2 (preview border) - 2 (wrap line)
preview_len=6

terminal_size=$(stty size < /dev/tty 2>/dev/null)
terminal_width=0
terminal_height=0

source "$HOME/.dotfiles/fzfscript/tty_size.sh"

if [ -n "$terminal_size" ]; then
    terminal_width=$(echo $terminal_size | awk '{print $2}')
    terminal_height=$(echo $terminal_size | awk '{print $1}')
fi

preview_len=6
if [ $(echo "$terminal_height") -ge $UP_HEIGHT_SIZE ]; then
    preview_len=6
elif [ $(echo "$terminal_width") -ge $RIGHT_WIDTH_SIZE ]; then
    tmp=$(expr $terminal_height - 4)
    preview_len=$(expr $tmp / 2)
    if [ $preview_len -le 0 ]; then
        preview_len=1
    fi
else
    if [ $(echo "$terminal_height") -ge $MAX_HEIGHT_SIZE ]; then
        preview_len=6
    elif [ $(echo "$terminal_height") -le $MIN_HEIGHT_SIZE ]; then
        preview_len=2
    else
        preview_height=$(expr ${terminal_height} - 11)
        preview_len=$(expr $preview_height / 2)
    fi
fi


startline=$(expr $line - $preview_len)
endline=$(expr $line + $preview_len)

if [ $startline -le 0 ]; then
    startline=1
fi

if [ $endline -ge $file_end_line ]; then
    endline=$file_end_line
fi

# sed -n "${startline},${endline}p" ${filename}

if [[ "$line" = "$startline" ]]; then

    endline=$(expr $line + $preview_len + $preview_len)
    endline_start=$(expr $line + 1)

    if [ -z "$(command -v bat)" ]; then
        # sed -n "${line}p" ${filename} | grep --color=always -F "$2"
        sed -n "${line}p" "${filename}" | grep --color=always -P ".*"
        sed -n "${endline_start},${endline}p" "${filename}"
    else
        bat -n --theme="Dracula" --color=always --line-range "${line}:${endline}" --highlight-line "$line" "${filename}"
        # bat -n --theme="Dracula" --color=always --line-range "${line}" --highlight-line "$line" ${filename} | grep --color=always -F "$2"
        # bat -n --theme="Dracula" --color=always --line-range "${endline_start}:${endline}" ${filename}
    fi

elif [[ "$line" = "$endline" ]]; then

    startline=$(expr $line - $preview_len - $preview_len)
    startline_end=$(expr $line - 1)

    if [ -z "$(command -v bat)" ]; then
        sed -n "${startline},${startline_end}p" "${filename}"
        sed -n "${line}p" "${filename}" | grep --color=always -P ".*"
        # sed -n "${line}p" ${filename} | grep --color=always -F "$2"
    else
        bat -n --theme="Dracula" --color=always --line-range "${startline}:${line}" --highlight-line "$line" "${filename}"
        # bat -n --theme="Dracula" --color=always --line-range "${startline}:${startline_end}" ${filename}
        # bat -n --theme="Dracula" --color=always --line-range "${line}" --highlight-line "$line" ${filename} | grep --color=always -F "$2"
    fi

else

    startline_end=$(expr $line - 1)
    endline_start=$(expr $line + 1)

    if [ -z "$(command -v bat)" ]; then
        sed -n "${startline},${startline_end}p" "${filename}"
        # sed -n "${line}p" ${filename} | grep --color=always -F "$2"
        sed -n "${line}p" "${filename}" | grep --color=always -P ".*"
        sed -n "${endline_start},${endline}p" "${filename}"
    else
        bat -n --theme="Dracula" --color=always --line-range "${startline}:${endline}" --highlight-line "$line" "${filename}"
        # bat -n --theme="Dracula" --color=always --line-range "${startline}:${startline_end}" ${filename}
        # bat -n --theme="Dracula" --color=always --line-range "${line}" --highlight-line "$line" ${filename} | grep --color=always -F "$2"
        # bat -n --theme="Dracula" --color=always --line-range "${endline_start}:${endline}" ${filename}
    fi

fi
