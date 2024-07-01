#!/bin/bash

if ! grep -q ":" <<< "$1"; then
    echo "Wrong input"
    exit 1
fi


filename=$(echo "$1" | awk -F ':' '{print $1}')
line=$(echo "$1" | awk -F ':' '{print $2}')

file_end_line=$(wc -l "$filename" | awk '{print $1}')


startline=$(expr $line - 10)
endline=$(expr $line + 10)

if [ $startline -le 0 ]; then
    startline=1
fi

if [ $endline -ge $file_end_line ]; then
    endline=$file_end_line
fi

# sed -n "${startline},${endline}p" ${filename}
echo "$2"

if [[ "$line" = "$startline" ]]; then
    endline=$(expr $line + 20)
    endline_start=$(expr $line + 1)

    sed -n "${line}p" ${filename} | grep --color=always -P "$2"
    sed -n "${endline_start},${endline}p" ${filename}

    exit 0
fi


if [[ "$line" = "$endline" ]]; then
    startline=$(expr $line - 20)
    startline_end=$(expr $line - 1)

    sed -n "${startline},${startline_end}p" ${filename}
    sed -n "${line}p" ${filename} | grep --color=always -P "$2"

    exit 0
fi


startline_end=$(expr $line - 1)
endline_start=$(expr $line + 1)

sed -n "${startline},${startline_end}p" ${filename}
sed -n "${line}p" ${filename} | grep --color=always -P "$2"
sed -n "${endline_start},${endline}p" ${filename}


