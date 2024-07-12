#!/bin/bash


if [ -z "$@" ]; then
    echo "no input"
    exit 1
fi

# code -s > /dev/null
# if [ $? -ne 0 ]; then
#     return
# fi

current_pwd="$(pwd)"

source $HOME/.dotfiles/grepscript/grep_exclude
search_str=( )
IFS='' search_str+=( ${exclude_str[@]} )

IFS='' search_str+=( "$@" )

output=""
output=$(grep --color=always -rnIHF ${search_str[@]} | sed -e "s|\:\[m\[K\s*|[m[K\n|2")

if [ -z "$output" ]; then
    echo "grep result is empty"
    exit 0
fi

output_array=()
IFS=$'\n' output_array=( $(echo "$output" ) )

results=""

for (( i=0; i<${#output_array[@]}; i+=2 )); do
    if [ -z "${output_array[$i]}" ]; then
        continue
    fi
    # results+="\n${output_array[$i+1]}    | ${output_array[$i]}"
    results+="${output_array[$i]}\n${output_array[$i+1]}\n\0"
    # results+="${output_array[$i]}\n${output_array[$i+1]}\0"
done

if [ -z "$results" ]; then
    echo "cannot find '$@'"
    exit 1
fi

echo -n -e "${results}"
