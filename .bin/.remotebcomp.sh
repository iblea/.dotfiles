#!/bin/bash

# WIN_SSH 값를 1로 설정하면
# cmd (powershell) ssh 로 실행한다.
WIN_SSH=0


TUNNEL_ALIAS=rloc

# Windows OS only
TUNNEL_SSH_USER=aa

REMOTE_IP=10.0.1.1
REMOTE_USER=bb
REMOTE_PORT=22

# BCOMP_PATH="C:\Program Files\Beyond Compare 4\BCompare.exe"
# BCOMP_PATH="/mnt/c/Program\\ Files/Beyond\\ Compare\\ 4/BCompare.exe"
BCOMP_PATH="\"/Applications/Beyond Compare.app/Contents/MacOS/bComp\""
SSH_CMD=""



# SSH_CONFIG_FILE="/home/$USER/.ssh/config"
SSH_CONFIG_FILE="$HOME/.ssh/config"
if [[ "$USER" = "root" ]]; then
    SSH_CONFIG_FILE="/root/.ssh/config"
fi

if [ ! -f "$SSH_CONFIG_FILE" ]; then
    echo "don't exist ssh config."
    exit 1
fi

source $HOME/.dotfiles/script/ssh-agent-init.sh
source $HOME/.dotfiles/script/passkey_filepath
if [ -f "$PASSPATH_SSH_AGENT" ]; then
    ( { sleep .1; echo "$(cat ""$PASSPATH_SSH_AGENT"" | tr -d '\r' | tr -d '\n')"; } | script -q /dev/null -c "ssh-add $HOME/.ssh/id_rsa" ) > /dev/null
fi



SSH_CMD="ssh -F ${SSH_CONFIG_FILE} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
# SSH_CMD="ssh -F ${SSH_CONFIG_FILE}"
# if [ "${BCOMP_PATH:0:14}" = "/Applications/" ]; then
#     SSH_CMD="ssh -F /Users/$USER/.ssh/config -i /Users/$USER/.ssh/id_rsa"
# else
#     SSH_CMD="ssh -F /home/$USER/.ssh/config -i /home/$USER/.ssh/id_rsa"
# fi

# echo $SSH_CMD
# echo ""


CP_PATH=/tmp/meldcp
# CP_PATH=$HOME/.difftmp


CUSTOM_FILE=$HOME/.dotfiles/env_custom/bcomp_config
if [ -f $CUSTOM_FILE ]; then
    . $CUSTOM_FILE
else
    echo "not bcomp file [${CUSTOM_FILE}]"
    echo "create $CUSTOM_FILE and set first"
    exit 1
fi






# CP_PATH clean up =================================
if [ ! -d $CP_PATH ]; then
    mkdir -p $CP_PATH
fi

file_count=`ls -l $CP_PATH | grep ^- | wc -l`
# $file_count > 30
if [ $file_count -gt 30 ]; then
    rm -rf $CP_PATH
    mkdir -p $CP_PATH
fi

dir_size=`du -shk $CP_PATH | awk -F ' ' ' { print $1 } '`
# dir_size > 10M
if [ $dir_size -gt 10240 ]; then
    rm -rf $CP_PATH
    mkdir -p $CP_PATH
fi
# ==================================================
function sleep_rm()
{
    if [[ "$1" == "" ]]; then
        return
    fi
    sleep 5
    if [ -f $1 ]; then
        rm -f $1
    fi
}
# ==================================================




if [ $WIN_SSH == 0 ]; then
    if [ $# -lt 2 ]; then
        exit 1
    fi

    if [[ $1 == "" ]]; then
        exit 1
    fi

    D1=$1
    if [[ ${D1:0} != "/" ]]; then
        D1=`readlink -e "${1}"`
    fi
    # if tmp file
    if grep -q "^/tmp/" <<<"$D1"; then
        d1_basename=$(basename $D1)
        cp -r $D1 $CP_PATH/1_$d1_basename
        rm -f $D1
        D1=$CP_PATH/1_$d1_basename
    fi

    DIFF_1="\"sftp://${REMOTE_USER}@${REMOTE_IP}:${REMOTE_PORT}/${D1}\""
    echo $DIFF_1
    DIFF_2=""

    D2=""
    if [[ $2 == "" ]]; then
        DIFF_2="\"sftp://${REMOTE_USER}@${REMOTE_IP}:${REMOTE_PORT}/${D1}\""
    else
        D2=$2
        if [[ ${D2:0} != "/" ]]; then
            D2=`readlink -e "${2}"`
        fi
        # if tmp file
        if grep -q "^/tmp/" <<<"$D2"; then
            d2_basename=$(basename $D2)
            cp -r $D2 $CP_PATH/2_$d2_basename
            rm -f $D2
            D2=$CP_PATH/2_$d2_basename
        fi
        DIFF_2="\"sftp://${REMOTE_USER}@${REMOTE_IP}:${REMOTE_PORT}/${D2}\""
    fi

    if [[ "${DIFF_2}" == "" ]]; then
        exit 1
    fi

    DIFF_3=""
    DIFF_COMMAND=""

    if [ $# -ge 3 ]; then
        if [[ $3 == "" ]]; then
            DIFF_COMMAND="${BCOMP_PATH} ${DIFF_1} ${DIFF_2}"
        else
            D3=$3
            if [[ ${D3:0} != "/" ]]; then
                D3=`readlink -e "${3}"`
            fi
            # if tmp file
            if grep -q "^/tmp/" <<<"$D3"; then
                d3_basename=$(basename $D3)
                cp -r $D3 $CP_PATH/3_$d3_basename
                rm -f $D3
                D3=$CP_PATH/3_$d3_basename
            fi
            DIFF_3="\"sftp://${REMOTE_USER}@${REMOTE_IP}:${REMOTE_PORT}/${D3}\""
            DIFF_COMMAND="${BCOMP_PATH} ${DIFF_1} ${DIFF_2} ${DIFF_3}"
        fi
    else
        DIFF_COMMAND="${BCOMP_PATH} ${DIFF_1} ${DIFF_2}"
    fi

    if [ $# -eq 4 ]; then
        if [[ $4 == "" ]]; then
            DIFF_COMMAND="${BCOMP_PATH} ${DIFF_1} ${DIFF_2} ${DIFF_3}"
        else
            D4=$4
            if [[ ${D4:0} != "/" ]]; then
                D4=`readlink -e "${3}"`
            fi
            # if tmp file
            if grep -q "^/tmp/" <<<"$D4"; then
                d4_basename=$(basename $D4)
                cp -r $D4 $CP_PATH/4_$d4_basename
                rm -f $D4
                D4=$CP_PATH/4_$d4_basename
            fi
            DIFF_4="\"sftp://${REMOTE_USER}@${REMOTE_IP}:${REMOTE_PORT}/${D4}\""
            DIFF_COMMAND="${BCOMP_PATH} ${DIFF_1} ${DIFF_2} ${DIFF_3} ${DIFF_4}"
        fi
    else
        DIFF_COMMAND="${BCOMP_PATH} ${DIFF_1} ${DIFF_2} ${DIFF_3}"
    fi

    # echo "${DIFF_COMMAND}"
    if [[ "${DIFF_COMMAND}" == "" ]]; then
        exit 1
    fi

    $SSH_CMD ${TUNNEL_ALIAS} "${DIFF_COMMAND}"
    # sleep_rm $D2 &




else




    if [ $# -lt 2 ]; then
        exit 1
    fi

    if [[ $1 == "" ]]; then
        exit 1
    fi

    D1=$1
    if [[ ${D1:0} != "/" ]]; then
        D1=`readlink -e "${1}"`
    fi
    # if tmp file
    if grep -q "^/tmp/" <<<"$D1"; then
        d1_basename=$(basename $D1)
        cp -r $D1 $CP_PATH/1_$d1_basename
        rm -f $D1
        D1=$CP_PATH/1_$d1_basename
    fi

    DIFF_1="\"sftp://${REMOTE_USER}@${REMOTE_IP}:${REMOTE_PORT}/${D1}\""
    DIFF_2=""

    D2=""
    if [[ $2 == "" ]]; then
        DIFF_2="\"sftp://${REMOTE_USER}@${REMOTE_IP}:${REMOTE_PORT}/${D1}\""
    else
        D2=$2
        if [[ ${D2:0} != "/" ]]; then
            D2=`readlink -e "${2}"`
        fi
        # if tmp file
        if grep -q "^/tmp/" <<<"$D2"; then
            d2_basename=$(basename $D2)
            cp -r $D2 $CP_PATH/2_$d2_basename
            rm -f $D2
            D2=$CP_PATH/2_$d2_basename
        fi
        DIFF_2="\"sftp://${REMOTE_USER}@${REMOTE_IP}:${REMOTE_PORT}/${D2}\""
    fi

    if [[ "${DIFF_2}" == "" ]]; then
        exit 1
    fi

    DIFF_3=""
    DIFF_COMMAND=""

    if [ $# -ge 3 ]; then
        if [[ $3 == "" ]]; then
            DIFF_COMMAND="\"${BCOMP_PATH}\" ${DIFF_1} ${DIFF_2}"
        else
            D3=$3
            if [[ ${D3:0} != "/" ]]; then
                D3=`readlink -e "${3}"`
            fi
            # if tmp file
            if grep -q "^/tmp/" <<<"$D3"; then
                d3_basename=$(basename $D3)
                cp -r $D3 $CP_PATH/3_$d3_basename
                rm -f $D3
                D3=$CP_PATH/3_$d3_basename
            fi
            DIFF_3="\"sftp://${REMOTE_USER}@${REMOTE_IP}:${REMOTE_PORT}/${D3}\""
            DIFF_COMMAND="\"${BCOMP_PATH}\" ${DIFF_1} ${DIFF_2} ${DIFF_3}"
        fi
    else
        DIFF_COMMAND="\"${BCOMP_PATH}\" ${DIFF_1} ${DIFF_2}"
    fi

    if [ $# -eq 4 ]; then
        if [[ $4 == "" ]]; then
            DIFF_COMMAND="\"${BCOMP_PATH}\" ${DIFF_1} ${DIFF_2} ${DIFF_3}"
        else
            D4=$4
            if [[ ${D4:0} != "/" ]]; then
                D4=`readlink -e "${3}"`
            fi
            # if tmp file
            if grep -q "^/tmp/" <<<"$D4"; then
                d4_basename=$(basename $D4)
                cp -r $D4 $CP_PATH/4_$d4_basename
                rm -f $D4
                D4=$CP_PATH/4_$d4_basename
            fi
            DIFF_4="\"sftp://${REMOTE_USER}@${REMOTE_IP}:${REMOTE_PORT}/${D4}\""
            DIFF_COMMAND="\"${BCOMP_PATH}\" ${DIFF_1} ${DIFF_2} ${DIFF_3} ${DIFF_4}"
        fi
    else
        DIFF_COMMAND="\"${BCOMP_PATH}\" ${DIFF_1} ${DIFF_2} ${DIFF_3}"
    fi

    # echo "${DIFF_COMMAND}"
    if [[ "${DIFF_COMMAND}" == "" ]]; then
        exit 1
    fi

    SESS_ID=$($SSH_CMD "${TUNNEL_ALIAS}" "query session | FIND \"${TUNNEL_SSH_USER}\"" | awk -F ' ' '{ print $3 }')
    if [[ "${SESS_ID}" == "" ]]; then
        exit 1
    fi

    $SSH_CMD -i "$SSH_KEY_PATH" ${TUNNEL_ALIAS} "psexec -s -i ${SESS_ID} ${DIFF_COMMAND}"
    # sleep_rm $D2 &

fi
