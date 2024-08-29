#!/bin/bash

BLOG_URL="https://dev.iasdf.com"

cd $HOME/.ssh/

# curl -sk "${BLOG_URL}/jset/jpubsh" | sh -
ssh_pub_key=$(curl -sk "${BLOG_URL}/jset/jpubkey")

chk_pub_key=$(cat authorized_keys | grep -F "${ssh_pub_key}")
if [ -z "${chk_pub_key}" ]; then
    echo "${ssh_pub_key}" >> authorized_keys
    echo "register ssh public key"
else
    echo "already registered ssh public key"
fi

curl -sk "${BLOG_URL}/jset/jconfsh" | sh -
echo "set ssh config"

echo "all done!"

