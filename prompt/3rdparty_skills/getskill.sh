#!/bin/bash

marketplace=(
    "https://github.com/anthropics/skills.git" "anthropic-agent-skills"
    "https://github.com/anthropics/claude-plugins-official.git" "claude-plugins-official"
    # "https://github.com/team-attention/plugins-for-claude-natives.git" "team-attention-plugins"
)

SKILLS_LIST=(
    "anthropic-agent-skills/skills/*"
    # "anthropic-agent-skills/skills/xlsx"
    # "anthropic-agent-skills/skills/docx"
    # "team-attention-plugins"
)

curpath=$(pwd)

basename_check=$(basename "$curpath")
if [[ "$basename_check" != "skills" ]]; then
    echo "this script must execute in 'skills' directory."
    exit 1
fi

scriptpath=$(dirname "$(realpath $0)")
cd "$scriptpath"


# 배열 길이만큼 반복하되, 인덱스를 2씩 증가시킴
for ((i=0; i<${#marketplace[@]}; i+=2)); do
    url="${marketplace[i]}"
    name="${marketplace[i+1]}"

    if [ ! -d "$name" ]; then
        # 디렉토리가 존재하지 않으면 클론
        echo "Cloning $name..."
        git clone "$url" "$name"
    else
        # 디렉토리가 이미 존재하면 최신 버전으로 업데이트
        echo "Directory $name already exists. Pulling latest..."
        git -C "$name" pull
    fi
done

# 스킬 목록 링킹

for pattern in "${SKILLS_LIST[@]}"; do
    for full_path in $pattern; do
        skillpath="${full_path%/*}"
        skillname="${full_path##*/}"
        # echo "skillpath: $skillpath"
        # echo "skillname: $skillname"
        # continue
        target="${curpath}/${skillname}.ln"

        # 깨진 링크가 있으면 삭제 (재매핑 준비)
        if [[ -L "$target" && ! -e "$target" ]]; then
            echo "Found broken link for $skillname. Removing..."
            rm -f "$target"
        fi

        if [[ ! -e "$target" && ! -L "$target" ]]; then
            # 절대 경로를 사용하여 안전하게 링크 생성
            ln -s "${scriptpath}/${full_path}" "$target"
            echo "Added skill: $skillname"
        else
            echo "Skipping (exists): $skillname"
        fi
    done
done
