#!/bin/bash

# Claude Code Stop hook - 완료 알림
# stdin으로 JSON 데이터가 들어옴

read -r input

# 프로젝트 디렉토리명 추출 (CLAUDE_PROJECT_DIR 환경변수 우선 사용)
if [[ -n "$CLAUDE_PROJECT_DIR" ]]; then
    full_path="$CLAUDE_PROJECT_DIR"
elif command -v jq &> /dev/null; then
    transcript=$(echo "$input" | jq -r '.transcript_path // empty')
    if [[ -n "$transcript" ]]; then
        full_path=$(dirname "$transcript")
    fi
fi

# 부모/현재 디렉토리 형식으로 만들기
if [[ -n "$full_path" ]]; then
    # 최상위 / 에서 작업하는 경우
    if [[ "$full_path" == "/" ]]; then
        project="/"
    else
        current=$(basename "$full_path")
        parent_path=$(dirname "$full_path")
        parent=$(basename "$parent_path")

        # 부모가 최상위면 /current
        if [[ "$parent_path" == "/" ]]; then
            project="/$current"
        else
            project="$parent/$current"
        fi
    fi
else
    project="Unknown"
fi

# 소리 알림
afplay /System/Library/Sounds/Ping.aiff &

# 시스템 알림
osascript -e "display notification \"Done!
$project\" with title \"Claude Code\""
