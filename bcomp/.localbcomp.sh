#!/bin/bash

# BEYOND COMPARE DEFAULT PATH
BCOMP_PATH=""
if [ -d "/mnt/c/Program Files/" ]; then
	# wsl
	BCOMP_PATH="/mnt/c/Program Files/Beyond Compare 4/BComp.exe"
	# BCOMP_PATH="/mnt/c/Program\ Files/Beyond\ Compare\ 4/BComp.exe"
else
	# mac
	BCOMP_PATH="/mnt/c/Program\ Files/Beyond\ Compare\ 4/BComp.exe"
fi

if [[ $1 == "" ]]; then
    exit 1
fi

# 파일의 절대경로 얻는 법
# $(dirname $(realpath $0))
# readlink -e $0
D1=$1
if [[ ${D1:0} != "/" ]]; then
    D1=`readlink -e "${1}"`
fi

DIFF_1="\"${D1:1}\""
DIFF_2=""

if [[ $2 == "" ]]; then
    DIFF_2="\"${D1:1}\""
else
    D2=$2
    if [[ ${D2:0} != "/" ]]; then
        D2=`readlink -e "${2}"`
    fi
    DIFF_2="\"${D2:1}\""
fi

if [[ "${DIFF_2}" == "" ]]; then
    exit 1
fi

DIFF_3=""
DIFF_COMMAND=""

if [[ $# == 3 ]]; then
    if [[ $3 == "" ]]; then
        DIFF_COMMAND="${DIFF_1} ${DIFF_2}"
    else
        D3=$3
        if [[ ${D3:0} != "/" ]]; then
            D3=`readlink -e "${3}"`
        fi
        DIFF_3="\"${D3:1}\""
        DIFF_COMMAND="${DIFF_1} ${DIFF_2} ${DIFF_3}"
    fi
else
    DIFF_COMMAND="${DIFF_1} ${DIFF_2}"
fi


# echo "${DIFF_COMMAND}"
if [[ "${DIFF_COMMAND}" == "" ]]; then
    exit 1
fi


cd / >> /dev/null
# ls -al "$BCOMP_PATH"
"$BCOMP_PATH" ${DIFF_COMMAND}
