if [ -n "$(command -v code)" ]; then
    code --goto "$@"
    exit 0
fi


fileinfo="$@"
# echo "fileinfo : $fileinfo"
filename="${fileinfo%:*}"
line="${fileinfo##*:}"

# echo "filename : $filename"
# echo "line : $line"
# vim +$line "$filename" -c 'normal zt'

echo "$filename" | xargs -I{} -o vim {} +${line}

# filename
# vim "$filename"