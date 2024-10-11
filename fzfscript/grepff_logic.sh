#!/bin/bash


source $HOME/.dotfiles/grepscript/grep_exclude
search_str=( )
IFS='' search_str+=( ${exclude_str[@]} )

search_string=""
if [[ "$1" = "-f" ]]; then
    IFS='' search_str+=( "${@:2}" )
elif [[ "$1" = "-m" ]]; then
    IFS='' search_str+=( "${@:2}" )
elif [[ "$1" = "-n" ]]; then
    IFS='' search_str+=( "${@:2}" )
else
    IFS='' search_str+=( "${@}" )
fi
# echo "search_str: ${search_str[@]}"

search_string=$(echo "${search_str[${#search_str[@]}-1]}")
# echo "search_string: $search_string"
# search_str[${#search_str[@]}-1]='"'"$search_string"'"'


# for s in "${search_str[@]}"; do
#     echo "s: '$s'"
# done

# if grep -q "zsh" <<< "$CURRENT_SHELL"; then
#     search_string=$(echo "${search_str[${#search_str[@]+1}]}")
# else
#     search_string=$(echo "${search_str[${#search_str[@]}-1]}")
# fi


# -P option : perl regex
# grep --color=always -rnIHP ${search_str[@]} | sed -e "p" -e "s/:/ | /2" | sed -n "2~2p"
# grep --color=always -rnIHP ${search_str[@]} | sed -e "s/:/ | /2" -e "s|\[m\[K\s*|[m[K|g"
# output=$(grep --color=always -rnIHP ${search_str[@]} | sed -e "s/:/ | /2")
output=""
preview_script="$HOME/.dotfiles/fzfscript/cat_n_preview.sh"
if [[ "$1" = "-f" ]]; then
    # echo "-f option"
    # output=$(grep --color=always -rnIHF ${search_str[@]} | sed -e "s/:/ | /2")
    output=$(grep --color=always -rnIHF ${search_str[@]} | sed -e "s|\:\[m\[K\s*|[m[K\n|2")
    preview_script="$HOME/.dotfiles/fzfscript/cat_m_preview.sh"
elif [[ "$1" = "-m" ]]; then
    # echo "-m option"
    # output=$(grep --color=always -rnIHF ${search_str[@]} | sed -e "s/:/ | /2")

    output=$(grep --color=always -rnIHF ${search_str[@]} | sed -e "s|\:\[m\[K\s*|[m[K\n|2")
    preview_script="$HOME/.dotfiles/fzfscript/cat_m_preview.sh"
elif [[ "$1" = "-n" ]]; then
    # echo "-n option"
    # output=$(grep --color=always -rnIHP ${search_str[@]} | sed -e "s/:/ | /2")
    output=$(grep --color=always -rnIHP ${search_str[@]} | sed -e "s|\:\[m\[K\s*|[m[K\n|2")
else
    # echo "other option"
    # output=$(grep --color=always -rnIHP ${search_str[@]} | sed -e "s/:/ | /2")
    output=$(grep --color=always -rnIHP ${search_str[@]} | sed -e "s|\:\[m\[K\s*|[m[K\n|2")
fi

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
    # results+="${output_array[$i]}\n${output_array[$i+1]}\n\0"

    # content=$( printf '%s' "${output_array[$i+1]}" | sed -e 's|\\|\\\\|g' )
    # echo, printf -> slower
    # null, newline change
    content="${output_array[$i+1]}"
    content="${content//\\/\\\\}"
    results+="${output_array[$i]}\n${content}\0"
    # content="${output_array[$i+1]}"
    # echo "content: $content"
    # results+="${output_array[$i]}\n${output_array[$i+1]}\0"
    # results+="${output_array[$i]}\n${output_array[$i+1]}\0"
done

# if grep -q "zsh" <<< "$CURRENT_SHELL"; then
#     for (( i=1; i<=${#output_array[@]}; i+=2 )); do
#         if [ -z "${output_array[$i]}" ]; then
#             continue
#         fi
#         # results+="\n${output_array[$i+1]}    | ${output_array[$i]}"
#         results+="${output_array[$i]}\n${output_array[$i+1]}\n\0"
#         # results+="${output_array[$i]}\n${output_array[$i+1]}\0"
#     done
# else
#     for (( i=0; i<${#output_array[@]}; i+=2 )); do
#         if [ -z "${output_array[$i]}" ]; then
#             continue
#         fi
#         # results+="\n${output_array[$i+1]}    | ${output_array[$i]}"
#         results+="${output_array[$i]}\n${output_array[$i+1]}\n\0"
#         # results+="${output_array[$i]}\n${output_array[$i+1]}\0"
#     done
# fi

if [ -z "$results" ]; then
    echo "cannot find '$@'"
    exit 1
fi

echo -n -e "${results}"

