#!/bin/bash

if ! grep -q ":" <<< "$1"; then
    echo "Wrong input"
    exit 1
fi


filename=$(echo "$1" | awk -F ':' '{print $1}')
line=$(echo "$1" | awk -F ':' '{print $2}')

file_end_line=$(wc -l "$filename" | awk '{print $1}')

preview_len=3

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
        sed -n "${line}p" ${filename} | grep --color=always -F "$2"
        sed -n "${endline_start},${endline}p" ${filename}
    else
        # bat -n --theme="Dracula" --color=always --line-range "${line}:${endline}"--highlight-line "$line" ${filename}
        bat -n --theme="Dracula" --color=always --line-range "${line}" --highlight-line "$line" ${filename} | grep --color=always -F "$2"
        bat -n --theme="Dracula" --color=always --line-range "${endline_start}:${endline}" ${filename}
    fi

elif [[ "$line" = "$endline" ]]; then

    startline=$(expr $line - $preview_len - $preview_len)
    startline_end=$(expr $line - 1)

    if [ -z "$(command -v bat)" ]; then
        sed -n "${startline},${startline_end}p" ${filename}
        sed -n "${line}p" ${filename} | grep --color=always -F "$2"
    else
        # bat -n --theme="Dracula" --color=always --line-range "${startline}:${line}" --highlight-line "$line" ${filename}
        bat -n --theme="Dracula" --color=always --line-range "${startline}:${startline_end}" ${filename}
        bat -n --theme="Dracula" --color=always --line-range "${line}" --highlight-line "$line" ${filename} | grep --color=always -F "$2"
    fi

else

    startline_end=$(expr $line - 1)
    endline_start=$(expr $line + 1)

    if [ -z "$(command -v bat)" ]; then
        sed -n "${startline},${startline_end}p" ${filename}
        sed -n "${line}p" ${filename} | grep --color=always -F "$2"
        sed -n "${endline_start},${endline}p" ${filename}
    else
        # bat -n --theme="Dracula" --color=always --line-range "${startline}:${endline}" --highlight-line "$line" ${filename}
        bat -n --theme="Dracula" --color=always --line-range "${startline}:${startline_end}" ${filename}
        bat -n --theme="Dracula" --color=always --line-range "${line}" --highlight-line "$line" ${filename} | grep --color=always -F "$2"
        bat -n --theme="Dracula" --color=always --line-range "${endline_start}:${endline}" ${filename}
    fi

fi
