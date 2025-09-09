#!/bin/bash


if [ -z "$(command -v ssh-agent)" ]; then
    echo "no ssh-agent"
    exit 1
fi

if [ -z "$(command -v ssh-add)" ]; then
    echo "no ssh-add"
    exit 1
fi

# if [ -z "$SSH_AUTH_SOCK" ]; then
#     export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"
# fi
export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"
source $HOME/.dotfiles/script/passkey_filepath


function ssh_agent_process_find()
{
    if [ -n "$(command -v ps)" ]; then
        local ssh_agent_proc=$(ps -aef | grep ssh-agent | grep -F "$SSH_AUTH_SOCK" | grep -v "grep")
        if [ -n "$ssh_agent_proc" ]; then
            echo "1"
            return 0
        fi
    fi

    if [ -n "$(command -v pgrep)" ]; then
        local ssh_agent_pgrep=$(pgrep "ssh-agent")
        if [ -z "${ssh_agent_pgrep}" ]; then
            echo "0"
            return 0
        fi
    fi

    if [ -n "$(command -v lsof)" ]; then
        local ssh_agent_lsof=$(lsof -c "ssh-agent" | grep -F "${SSH_AUTH_SOCK}")
        if [ -z "${ssh_agent_lsof}" ]; then
            echo "0"
            return 0
        fi
    fi

    echo "1"
    return 0
}

SSH_AUTH_DIR=$(dirname "$SSH_AUTH_SOCK")
if [ ! -d "${SSH_AUTH_DIR}" ]; then
    mkdir -p "${SSH_AUTH_DIR}"
fi
unset SSH_AUTH_DIR
ssh_agent_found=$(ssh_agent_process_find )
if [[ "${ssh_agent_found}" = "0" ]]; then
    if [ -S  "${SSH_AUTH_SOCK}" ] || [ -f  "${SSH_AUTH_SOCK}" ]; then
        /bin/rm -f "${SSH_AUTH_SOCK}"
    fi
    eval $(ssh-agent -s -a "${SSH_AUTH_SOCK}") > /dev/null
fi
unset ssh_agent_found

# ssh-add $HOME/.ssh/id_rsa

# ( { sleep .1; echo -n 'test'; } | script -q /dev/null -c "ssh-add $HOME/.ssh/id_rsa" )
if [ -f "$PASSPATH_SSH_AGENT" ]; then
    ssh_agent_found=$(ssh_agent_process_find )
    if [[ "${ssh_agent_found}" = "1" ]]; then
		$HOME/.dotfiles/script/pass-ssh-agent.sh > /dev/null
		# $HOME/.dotfiles/script/pass-ssh-agent.sh
    fi
fi



if [[ "$(uname -s)" = "Darwin" ]]; then
    echo -n ""
fi
