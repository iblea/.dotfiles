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

if [ $# -lt 2 ]; then
    echo "argument is not enough"
    exit 1
fi

if [ $# -gt 4 ]; then
    echo "argument is too many"
    exit 1
fi


# CP_PATH=/tmp/meldcp
CP_PATH=$HOME/.bcomptmp
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



# 파일의 절대경로 얻는 법
# $(dirname $(realpath $0))
# readlink -e $0
D1=$1
DIFF_1=""
if [[ ${D1:0} != "/" ]]; then
    D1=`$GETLINK -e "${1}"`
fi

# if tmp file
if [ -d /Applications/ ]; then
    if grep -q "^/private/var/folders/" <<<"$D1"; then
        # if grep -q "/clipboard_" <<<"$D1"; then
        d1_basename=$(basename $D1)
        cp -r $D1 $CP_PATH/1_$d1_basename
        rm -f $D1
        D1=$CP_PATH/1_$d1_basename
        # fi
    fi
else
    if grep -q "^/tmp/" <<<"$D1"; then
        d1_basename=$(basename $D1)
        cp -r $D1 $CP_PATH/1_$d1_basename
        rm -f $D1
        D1=$CP_PATH/1_$d1_basename
    fi
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

    # if tmp file
    if [ -d /Applications/ ]; then
        if grep -q "^/private/var/folders/" <<<"$D2"; then
            # if grep -q "/clipboard_" <<<"$D2"; then
            d2_basename=$(basename $D2)
            cp -r $D2 $CP_PATH/2_$d2_basename
            rm -f $D2
            D2=$CP_PATH/2_$d2_basename
            # fi
        fi
    else
        if grep -q "^/tmp/" <<<"$D2"; then
            d2_basename=$(basename $D2)
            cp -r $D2 $CP_PATH/2_$d2_basename
            rm -f $D2
            D2=$CP_PATH/2_$d2_basename
        fi
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

if [ $# -eq 3 ]; then
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

        # if tmp file
        if [ -d /Applications/ ]; then
            if grep -q "^/private/var/folders/" <<<"$D3"; then
                # if grep -q "/clipboard_" <<<"$D3"; then
                d3_basename=$(basename $D3)
                cp -r $D3 $CP_PATH/3_$d3_basename
                rm -f $D3
                D3=$CP_PATH/3_$d3_basename
                # fi
            fi
        else
            if grep -q "^/tmp/" <<<"$D3"; then
                d3_basename=$(basename $D3)
                cp -r $D3 $CP_PATH/3_$d3_basename
                rm -f $D3
                D3=$CP_PATH/3_$d3_basename
            fi
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

DIFF_4=""
if [ $# -eq 4 ]; then
    if [[ $4 == "" ]]; then
        if [ $OS -eq 2 ]; then
            DIFF_COMMAND="\"${DIFF_1}\" \"${DIFF_2}\" \"${DIFF_3}\""
        else
            DIFF_COMMAND="${DIFF_1} ${DIFF_2} ${DIFF_3}"
        fi
    else
        D4=$3
        if [[ ${D4:0} != "/" ]]; then
            D4=`$GETLINK -e "${4}"`
        fi

        # if tmp file
        if [ -d /Applications/ ]; then
            if grep -q "^/private/var/folders/" <<<"$D4"; then
                # if grep -q "/clipboard_" <<<"$D4"; then
                d4_basename=$(basename $D4)
                cp -r $D4 $CP_PATH/4_$d4_basename
                rm -f $D4
                D4=$CP_PATH/4_$d4_basename
                # fi
            fi
        else
            if grep -q "^/tmp/" <<<"$D4"; then
                d4_basename=$(basename $D4)
                cp -r $D4 $CP_PATH/4_$d4_basename
                rm -f $D4
                D4=$CP_PATH/4_$d4_basename
            fi
        fi

        if [ $OS -eq 2 ]; then
            DIFF_4="${D4}"
        else
            DIFF_4="\"${D4:1}\""
        fi
        DIFF_COMMAND="${DIFF_1} ${DIFF_2} ${DIFF_3} ${DIFF_4}"
        if [ $OS -eq 2 ]; then
            DIFF_COMMAND="\"${DIFF_1}\" \"${DIFF_2}\" \"${DIFF_3}\" \"${DIFF_4}\""
        else
            DIFF_COMMAND="${DIFF_1} ${DIFF_2} ${DIFF_3} ${DIFF_4}"
        fi
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


