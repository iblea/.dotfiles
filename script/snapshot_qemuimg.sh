#!/bin/bash

curpath=$(dirname "$(realpath $0)")
cd "$curpath"

SNAPSHOT_SAVE_FILE="$curpath/.name_of_snapshot_utm.txt"
IMAGE_PATH=""
# echo "name: $SNAPSHOT_SAVE_FILE"

function description() {
    # 스냅샷 생성
    qemu-img snapshot -c 스냅샷_이름 이미지_파일명

    # 2. 스냅샷 조회
    qemu-img snapshot -l 이미지_파일명

    # 3. 스냅샷 복구
    qemu-img snapshot -a 스냅샷_이름 이미지_파일명

    # 4. 스냅샷 삭제
    qemu-img snapshot -d 스냅샷_이름 이미지_파일명
}

function help_func() {
    echo "usage: $0 [help|add|list|rb|del|vm]"
    echo "$0 help"
    echo "$0 add <snapshot_name>"
    echo "$0 list"
    echo "$0 rb (rollback) <snapshot_name>"
    echo "$0 del (delete) <snapshot_name>"
    echo "$0 vm"
}

function select_vm() {
    # find utm -name "*.qcow2" -type f
    # find . -maxdepth 1 -mindepth 1 -type d

    # readarray 대신 while read 사용 (호환성)
    counter=1
    findlist=()
    while IFS= read -r line; do
        findlist+=("$line")
    done < <(find utm -name "*.qcow2" -type f)

    for path in "${findlist[@]}"; do
        echo "$counter. $path"
        ((counter++))
    done

    # 사용자 입력 받기
    echo ""
    echo -n "Enter directory number: "
    read selected_number

    # 입력 검증
    if ! [[ "$selected_number" =~ ^[0-9]+$ ]]; then
        echo "wrong argument"
        exit 1
    fi

    # 범위 검증 (1부터 배열 크기까지)
    array_size=${#findlist[@]}
    if [ "$selected_number" -lt 1 ] || [ "$selected_number" -gt "$array_size" ]; then
        echo "wrong argument"
        exit 1
    fi

    # 선택된 디렉토리 출력 (배열 인덱스는 0부터 시작하므로 -1)
    selected_index=$((selected_number - 1))
    selected_path="${findlist[$selected_index]}"
    echo "selected_path: '$selected_path'"
    echo -n "$selected_path" > "$SNAPSHOT_SAVE_FILE"
    echo "saved done!"
    echo "save file context: '$(cat "$SNAPSHOT_SAVE_FILE")'"
}

function list_snapshot() {
	echo "snapshot information"
	echo "path: '${IMAGE_PATH}'"
	echo ""
	echo "list snapshot"

    qemu-img snapshot -l "${IMAGE_PATH}"
}


if [ "$1" = "help" ]; then
	help_func
    exit 0
fi


if [ "$1" = "vm" ]; then
	select_vm
	echo ""
    exit 0
fi


if [ ! -f "$SNAPSHOT_SAVE_FILE" ]; then
    echo "cannot find savefile path : '${SNAPSHOT_SAVE_FILE}'"
    # find utm -name "*.qcow2" -type f
    touch "$SNAPSHOT_SAVE_FILE"
    echo "save qcow2 file name to '${SNAPSHOT_SAVE_FILE}'"
	echo ""
	select_vm
	echo ""
fi

IMAGE_PATH="$(cat "$SNAPSHOT_SAVE_FILE")"
if [ ! -f "$IMAGE_PATH" ]; then
    echo "cannot find image path : '${IMAGE_PATH}'"
	echo ""
	select_vm
	echo ""
	IMAGE_PATH="$(cat "$SNAPSHOT_SAVE_FILE")"
fi

echo "SNAPSHOT IMAGE_PATH: '${IMAGE_PATH}'"

if [ ! -f "$IMAGE_PATH" ]; then
    echo "cannot find image path : '${IMAGE_PATH}'"
	echo "script error!"
	exit 0
fi

if [ $# -le 0 ]; then
	list_snapshot
    exit 0
fi



if [ "$1" = "add" ]; then

    if [ $# -le 1 ]; then
        echo ""
        echo "wrong argument"
        echo "input snapshot name to add"
        echo ""
        exit 1
    fi
    snapshot_name="$2"
	echo "snapshot information"
	echo "path: '${IMAGE_PATH}'"
	echo "name: '${snapshot_name}'"
	echo ""
	# read -s -n1 -p "Press any key to continue..."
	read -s -n1 -p "Really? (y/n): " answer
	echo
	if [[ "$answer" != "y" ]] && [[ "$answer" != "yes" ]]; then
		echo "stop script!"
		exit 1
	fi
    qemu-img snapshot -c "${snapshot_name}" "${IMAGE_PATH}"
	echo "Done!"
    exit 0

fi


if [ "$1" = "list" ]; then
	list_snapshot
    exit 0
fi


if [ "$1" = "rb" ] || [ "$1" = "rollback" ]; then

    if [ $# -le 1 ]; then
        echo ""
        echo "wrong argument"
        echo "input snapshot name to rollback"
        echo ""
        exit 1
    fi
    snapshot_name="$2"
	echo "snapshot information"
	echo "path: '${IMAGE_PATH}'"
	echo "name: '${snapshot_name}'"
	echo
	read -s -n1 -p "Really? (y/n): " answer
	echo
	if [[ "$answer" != "y" ]] && [[ "$answer" != "yes" ]]; then
		echo "stop script!"
		exit 1
	fi
	echo "Done!"
    qemu-img snapshot -a "${snapshot_name}" "${IMAGE_PATH}"

fi


if [ "$1" = "del" ] || [ "$1" = "delete" ]; then

    if [ $# -le 1 ]; then
        echo ""
        echo "wrong argument"
        echo "input snapshot name to delete"
        echo ""
        exit 1
    fi
    snapshot_name="$2"
	echo "snapshot information"
	echo "path: '${IMAGE_PATH}'"
	echo "name: '${snapshot_name}'"
	echo ""
	read -s -n1 -p "Really? (y/n): " answer
	echo
	if [[ "$answer" != "y" ]] && [[ "$answer" != "yes" ]]; then
		echo "stop script!"
		exit 1
	fi
    qemu-img snapshot -d "${snapshot_name}" "${IMAGE_PATH}"
	echo "Done!"
    exit 0
fi


