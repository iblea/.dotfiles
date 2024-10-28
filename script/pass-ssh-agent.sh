#!/bin/bash

# #!/usr/bin/expect
# set timeout -1
# spawn ssh-add /path/to/.ssh/id_rsa
# expect "Enter passphrase for /path/to/.ssh/id_rsa:"
# send "password\n"



source $HOME/.dotfiles/script/passkey_filepath

PASSWORD=$(cat ""$PASSPATH_SSH_AGENT"" | tr -d '\r' | tr -d '\n')
PRIV_PATH="$HOME/.ssh/id_rsa"

if [[ "$(uname -s)" = "Darwin" ]]; then

/usr/bin/expect <<EOF
# infinity
# set timeout -1
# limit 3
set timeout 3
spawn ssh-add $PRIV_PATH
match_max 100000
expect -exact "Enter passphrase for $PRIV_PATH: "
send -- "$PASSWORD\n"
expect eof
EOF

else

( { sleep .1; echo "$PASSWORD"; } | script -q /dev/null -c "ssh-add ${PRIV_PATH}" )

fi

