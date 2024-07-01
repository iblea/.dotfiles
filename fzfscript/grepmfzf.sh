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
    local exclude_dirs=( ".git" ".svn" "node_modules" "__pycache__" )

    local search_str=()
    for exclude_dir in "${exclude_dirs[@]}"; do
        search_str+=( "--exclude-dir='${exclude_dir}'" )
    done

    IFS='' search_str+=( "$@" )

    local output=""
    output=$(grep --color=always -rnIHF ${search_str[@]} | sed -e "s|\:\[m\[K\s*|[m[K\n|2")

    if [ -z "$output" ]; then
        echo "grep result is empty"
        return
    fi


    local ORG_IFS=$IFS
    local output_array=()

    IFS=$'\n' output_array=( $(echo "$output" ) )

    IFS=$ORG_IFS
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

    echo -e "${results}"

}


grepfzf_function "$@"
