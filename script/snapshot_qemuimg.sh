#!/bin/bash

IMAGE_PATH="ubuntu24.utm/Data/B50A1CD3-659E-47E9-8313-2B45F52D0910.qcow2"

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


curpath=$(dirname "$(realpath $0)")
cd "$curpath"

if [ ! -f "${IMAGE_PATH}" ]; then
    echo "cannot find image path : '${IMAGE_PATH}'"
    exit 1
fi

if [ $# -le 0 ]; then
    qemu-img snapshot -l "${IMAGE_PATH}"
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
    qemu-img snapshot -c "${snapshot_name}" "${IMAGE_PATH}"
    exit 0

fi


if [ "$1" = "list" ]; then
    qemu-img snapshot -l "${IMAGE_PATH}"
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
    qemu-img snapshot -a "${snapshot_name}" "${IMAGE_PATH}"

fi


if [ "$1" = "del" ] || [ "$1" = "delete"]; then

    if [ $# -le 1 ]; then
        echo ""
        echo "wrong argument"
        echo "input snapshot name to delete"
        echo ""
        exit 1
    fi
    snapshot_name="$2"
    qemu-img snapshot -d "${snapshot_name}" "${IMAGE_PATH}"
    exit 0

fi

