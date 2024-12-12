

function cd() {
    # If we don't have exactly one argument that is a valid dir...
    if ! [[ $# -eq 1 && -d "$PWD"/"$1" ]]; then
        # ...then just use the default behavior.
        builtin cd "$@"
        # ls --color=auto -AF
        # echo ""
        pwd
        return
    fi

    # Get the absolute path of where normal `cd <arg1>` would take us.
    local dir=${${:-"$PWD"/"$1"}:A}
    local finder=$(find "${dir}" -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print -quit 2>/dev/null)
    if [ -z "${finder}" ]; then
        builtin cd "$@"
        # ls --color=auto -AF
        # echo ""
        pwd
        return
    fi

    if [[ "$1" = "/" ]]; then
        builtin cd "$@"
        pwd
        return
    fi

    if [[ "$1" = ".." ]] || [[ "$1" = "../" ]]; then
        # List the children of that dir.
        # local -a children=( $dir/* )
        # local -a children=( $(ls -1A $dir) )
        local -a children=( $(find "${dir}" -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print 2>/dev/null) )

        # Keep going up until we find a dir with more than one child.
        while [[ ${#dir} -gt 1 ]] && [[ ${#children[@]} -eq 1 ]] && [[ -d "${children[@]}" ]]; do
            dir=$dir:h
            finder=$(find "${dir}" -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print -quit 2>/dev/null)
            if [ -z "${finder}" ]; then
                break
            fi
            # children=( $dir/* )
            children=( $(find "${dir}" -mindepth 1 -maxdepth 1 -not -path '*/\.*' -type d -print 2>/dev/null) )
            children+=( $(find "${dir}" -mindepth 1 -maxdepth 1 -not -path '*/\.*' -type f -print -quit 2>/dev/null) )
        done
    elif [[ "${1:0:2}" = "./" ]]; then
        builtin cd "$dir"
        # ls --color=auto -AF
        # echo ""
        pwd
        return
    else
        # check ../../../
        if [[ "${1:0:2}" = ".." ]]; then
            fullpath="$1"
            fullpath="${fullpath//./}"
            fullpath="${fullpath//\//}"
            if [ -z "$fullpath" ]; then
                builtin cd "$1"
                # ls --color=auto -AF
                # echo ""
                pwd
                return
            fi
        fi
        # List the children of that dir.
        # local -a children=( $dir/* )
        # local -a children=( $(ls -1A $dir) )
        local -a children=( $(find "${dir}" -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print 2>/dev/null) )

        # Keep going down as long as we find exactly one child and it's a dir.
        while [[ ${#children[@]} -eq 1 && -d $children ]]; do
            dir=$children
            finder=$(find "${dir}" -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print -quit 2>/dev/null)
            if [ -z "${finder}" ]; then
                break
            fi
            # children=( $dir/* )
            children=( $(find "${dir}" -mindepth 1 -maxdepth 1 -not -path '*/\.*' -type d -print 2>/dev/null) )
            children+=( $(find "${dir}" -mindepth 1 -maxdepth 1 -not -path '*/\.*' -type f -print -quit 2>/dev/null) )
        done
    fi

    # Pass the resulting path to `cd`.
    builtin cd "$dir"
    # ls --color=auto -AF
    # echo ""
    pwd
}
