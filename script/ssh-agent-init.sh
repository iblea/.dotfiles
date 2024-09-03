#!/bin/bash


if [ -z "$(command -v ssh-agent)" ]; then
    echo "no ssh-agent"
    exit 1
fi

if [ -z "$(command -v ssh-add)" ]; then
    echo "no ssh-add"
    exit 1
fi


if [ -z "$SSH_AUTH_SOCK" ]; then
    export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"
fi
# export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"

SSH_AUTH_DIR=$(dirname "$SSH_AUTH_SOCK")
if [ ! -d "${SSH_AUTH_DIR}" ]; then
    mkdir -p "${SSH_AUTH_DIR}"
fi
unset SSH_AUTH_DIR
ssh_agent_proc=$(ps -aef | grep ssh-agent | grep -F "$SSH_AUTH_SOCK" | grep -v "grep")
if [ -z "$ssh_agent_proc" ]; then
    eval $(ssh-agent -s -a "${SSH_AUTH_SOCK}") > /dev/null
fi
unset ssh_agent_proc

# ssh-add $HOME/.ssh/id_rsa

