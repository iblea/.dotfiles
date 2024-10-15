
if ( grep -q "ERROR: grep result is empty" <<< "$@" ); then
    echo "1" >> /tmp/test.txt
    exit 1
elif ( grep -q "ERROR: cannot find" <<< "$@" ); then
    echo "2" >> /tmp/test.txt
    exit 1
fi

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