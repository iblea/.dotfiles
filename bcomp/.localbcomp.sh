#!/bin/bash

# BEYOND COMPARE DEFAULT PATH
BCOMP_PATH=""
GETLINK=""
OS=0
if [ -d "/mnt/c/Program Files/" ]; then
	# wsl
	BCOMP_PATH="/mnt/c/Program Files/Beyond Compare 4/BComp.exe"
	# BCOMP_PATH="/mnt/c/Program\ Files/Beyond\ Compare\ 4/BComp.exe"
    GETLINK=readlink
    OS=1
elif [ -d "/Applications/" ]; then
	# mac
	BCOMP_PATH="/Applications/Beyond Compare.app/Contents/MacOS/bComp"
    GETLINK=greadlink
    OS=2
else
	echo "cannot found os"
	exit 1
fi

if [[ $1 == "" ]]; then
    exit 1
fi


# 파일의 절대경로 얻는 법
# $(dirname $(realpath $0))
# readlink -e $0
D1=$1
DIFF_1=""
if [[ ${D1:0} != "/" ]]; then
    D1=`$GETLINK -e "${1}"`
fi

if [ $OS -eq 2 ]; then
    DIFF_1="${D1}"
else
    DIFF_1="\"${D1:1}\""
fi
DIFF_2=""

if [[ $2 == "" ]]; then
    if [ $OS -eq 2 ]; then
        DIFF_2="${D1}"
    else
        DIFF_2="\"${D1:1}\""
    fi
else
    D2=$2
    if [[ ${D2:0} != "/" ]]; then
        D2=`$GETLINK -e "${2}"`
    fi
    if [ $OS -eq 2 ]; then
        DIFF_2="${D2}"
    else
        DIFF_2="\"${D2:1}\""
    fi
fi

if [[ "${DIFF_2}" == "" ]]; then
    exit 1
fi

DIFF_3=""
DIFF_COMMAND=""

if [[ $# == 3 ]]; then
    if [[ $3 == "" ]]; then
        if [ $OS -eq 2 ]; then
            DIFF_COMMAND="\"${DIFF_1}\" \"${DIFF_2}\""
        else
            DIFF_COMMAND="${DIFF_1} ${DIFF_2}"
        fi
    else
        D3=$3
        if [[ ${D3:0} != "/" ]]; then
            D3=`$GETLINK -e "${3}"`
        fi
        if [ $OS -eq 2 ]; then
            DIFF_3="${D3}"
        else
            DIFF_3="\"${D3:1}\""
        fi
        DIFF_COMMAND="${DIFF_1} ${DIFF_2} ${DIFF_3}"
        if [ $OS -eq 2 ]; then
            DIFF_COMMAND="\"${DIFF_1}\" \"${DIFF_2}\" \"${DIFF_3}\""
        else
            DIFF_COMMAND="${DIFF_1} ${DIFF_2} ${DIFF_3}"
        fi

    fi
else
    if [ $OS -eq 2 ]; then
        DIFF_COMMAND="\"${DIFF_1}\" \"${DIFF_2}\""
    else
        DIFF_COMMAND="${DIFF_1} ${DIFF_2}"
    fi
fi


# echo "${DIFF_COMMAND}"
if [[ "${DIFF_COMMAND}" == "" ]]; then
    exit 1
fi

cd / >> /dev/null
if [ $OS -eq 2 ]; then
    # 공백 디렉토리, 파일의 경우 에러가 발생하여 echo 문으로 처리 후 pipe로 전달
    echo "\"$BCOMP_PATH\" ${DIFF_COMMAND}" | /bin/bash -
else
    # ls -al "$BCOMP_PATH"
    "$BCOMP_PATH" ${DIFF_COMMAND}
fi


