#!/bin/zsh


function grepfzf_function() {

    if [ -z "$@" ]; then
        echo "no input"
        return
    fi

    # code -s > /dev/null
    # if [ $? -ne 0 ]; then
    #     return
    # fi
    local exclude_dirs=( ".git" ".svn" "node_modules" "__pycache__" )
    local search_str=()
    for exclude_dir in "${exclude_dirs[@]}"; do
        search_str+=( "--exclude-dir='${exclude_dir}'" )
    done
    IFS='' search_str+=( "$@" )

    # if [[ "$1" = "-f" ]]; then
    #     IFS='' search_str+=( "${@:2}" )
    # elif [[ "$1" = "-n" ]]; then
    #     IFS='' search_str+=( "${@:2}" )
    # else
    #     IFS='' search_str+=( "$@" )
    # fi

    local current_pwd="$(pwd)"

    # -P option : perl regex
    # grep --color=always -rnIHP ${search_str[@]} | sed -e "p" -e "s/:/ | /2" | sed -n "2~2p"
    # grep --color=always -rnIHP ${search_str[@]} | sed -e "s/:/ | /2" -e "s|\[m\[K\s*|[m[K|g"
    # output=$(grep --color=always -rnIHP ${search_str[@]} | sed -e "s/:/ | /2")

    local output=""
    output=$(grep --color=always -rnIHP ${search_str[@]} | sed -e "s|\:\[m\[K\s*|[m[K\n|2")

    # if [[ "$1" = "-f" ]]; then
    #     # echo "-f option"
    #     # output=$(grep --color=always -rnIHF ${search_str[@]} | sed -e "s/:/ | /2")
    #     output=$(grep --color=always -rnIHF ${search_str[@]} | sed -e "s|\:\[m\[K\s*|[m[K\n|2")
    # elif [[ "$1" = "-n" ]]; then
    #     # echo "-n option"
    #     # output=$(grep --color=always -rnIHP ${search_str[@]} | sed -e "s/:/ | /2")
    #     output=$(grep --color=always -rnIHP ${search_str[@]} | sed -e "s|\:\[m\[K\s*|[m[K\n|2")
    # else
    #     # echo "other option"
    #     # output=$(grep --color=always -rnIHP ${search_str[@]} | sed -e "s/:/ | /2")
    #     output=$(grep --color=always -rnIHP ${search_str[@]} | sed -e "s|\:\[m\[K\s*|[m[K\n|2")
    # fi

    if [ -z "$output" ]; then
        echo "grep result is empty"
        return
    fi


    local ORG_IFS=$IFS
    local output_array=()

    # current shell
    local CURRENT_SHELL=$(ps -p $$ -o 'comm=')

    IFS=$'\n' output_array=( $(echo "$output" ) )

    IFS=$ORG_IFS
    local results=""

    if grep -q "/zsh" <<< "$CURRENT_SHELL"; then
        for (( i=1; i<=${#output_array[@]}; i+=2 )); do
            if [ -z "${output_array[$i]}" ]; then
                continue
            fi
            # results+="\n${output_array[$i+1]}    | ${output_array[$i]}"
            results+="${output_array[$i]}\n${output_array[$i+1]}\n\0"
            # results+="${output_array[$i]}\n${output_array[$i+1]}\0"
        done
    else
        for (( i=0; i<${#output_array[@]}; i+=2 )); do
            if [ -z "${output_array[$i]}" ]; then
                continue
            fi
            # results+="\n${output_array[$i+1]}    | ${output_array[$i]}"
            results+="${output_array[$i]}\n${output_array[$i+1]}\n\0"
            # results+="${output_array[$i]}\n${output_array[$i+1]}\0"
        done
    fi


    if [ -z "$results" ]; then
        echo "cannot find '$@'"
        return
    fi

    results=${results:0:${#results}-4}
    echo "${results}"

}


grepfzf_function "$@"
