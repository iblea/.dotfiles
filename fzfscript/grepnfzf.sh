#!/bin/bash


function grepfzf_function() {

    if [ -z "$@" ]; then
        echo "no input"
        return
    fi

    # code -s > /dev/null
    # if [ $? -ne 0 ]; then
    #     return
    # fi

    local current_pwd="$(pwd)"

    source $HOME/.dotfiles/grepscript/grep_exclude
    local search_str=( )
    IFS='' search_str+=( ${exclude_str[@]} )

    IFS='' search_str+=( "$@" )

    local output=""
    output=$(grep --color=always -rnIHP ${search_str[@]} | sed -e "s|\:\[m\[K\s*|[m[K\n|2")

    if [ -z "$output" ]; then
        echo "grep result is empty"
        return
    fi

    local output_array=()
    IFS=$'\n' output_array=( $(echo "$output" ) )

    local results=""

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
        return
    fi

    echo -n -e "${results}"

}


grepfzf_function "$@"
