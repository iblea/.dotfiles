#!/bin/bash
set -euo pipefail

curpath=$(readlink -e $(dirname "$0"))

# 전용 tmux 소켓 사용.
# (사용자 전역 tmux 설정에 destroy-unattached on 이 걸려 있어
#  기본 서버에서는 detached 세션이 즉시 파괴됨. 별도 소켓 + 빈 conf 로 격리)
SOCK="bgaiagent"
SESSION="bgaiagent_sess_$$"
LOGFILE="$curpath/output/bgtmux.log"
OUTPUT_FILE="$curpath/output/bgtmux.txt"
PROMPT=$(cat << 'EOF'
오늘 서울 강서/경기도 부천은 자전거 타기 좋은 날씨임?
(curl / wget 명령과 같은 bash 명령은 일체 사용 금지)

정리된 내용을 _@OUTPUT@_ 에 저장해 줘.
EOF
)

PROMPT=$(echo "$PROMPT" | sed "s|_@OUTPUT@_|${OUTPUT_FILE}|g")
# echo "$PROMPT"

if [ ! -f "$OUTPUT_FILE" ]; then
    rm -f "$OUTPUT_FILE"
fi

TM() { tmux -L "$SOCK" -f /dev/null "$@"; }

# 종료 시 항상 tmux 서버 정리
cleanup() {
    TM kill-server 2>/dev/null || true
}
trap cleanup EXIT

# 1. 백그라운드에서 tmux 세션 생성
TM new-session -d -s "$SESSION" -x 220 -y 50

# 2. 작업 경로 이동
TM send-keys -t "$SESSION" "cd \"$curpath\"" Enter


# claude 시작 전 적용할 환경변수 / claude 시작 명령어
CLAUDE_CODE_EFFORT_LEVEL="medium"
CLAUDE_NO_CONTEXT_COMMAND='claude --system-prompt "" --setting-sources "" --disable-slash-commands --strict-mcp-config --model Opus --allowedTools "Glob" "Grep" "Read" "Edit" "Write" "WebSearch" "WebFetch"'

# 3. claude 실행 (환경변수 적용 후 시작 명령어 실행)
#    ANTHROPIC_API_KEY 에 잘못된 값이 들어가 있어 제거 후 실행
TM send-keys -t "$SESSION" "unset ANTHROPIC_API_KEY" Enter
TM send-keys -t "$SESSION" "export CLAUDE_CODE_EFFORT_LEVEL=\"$CLAUDE_CODE_EFFORT_LEVEL\"" Enter
TM send-keys -t "$SESSION" "$CLAUDE_NO_CONTEXT_COMMAND" Enter

# codex TUI 가 뜰 때까지 대기
sleep 6

# 4. 프롬프트 입력 후 Enter
TM send-keys -t "$SESSION" "$PROMPT"
sleep 1
TM send-keys -t "$SESSION" Enter

# 5. 응답 대기: 화면 출력이 안정될 때까지 폴링
#    (codex 응답 완료를 직접 감지할 수 없어, 일정 시간 화면 변화가
#     없으면 답변이 끝난 것으로 간주)
STABLE_NEEDED=4      # 연속 N회 변화 없으면 완료로 판단
POLL_INTERVAL=3      # 폴링 간격(초)
MAX_WAIT=180         # 최대 대기(초) - 무한 대기 방지

prev=""
stable=0
elapsed=0
while [ "$elapsed" -lt "$MAX_WAIT" ]; do
    sleep "$POLL_INTERVAL"
    elapsed=$((elapsed + POLL_INTERVAL))
    cur="$(TM capture-pane -t "$SESSION" -p)"
    if [ "$cur" = "$prev" ]; then
        stable=$((stable + 1))
        [ "$stable" -ge "$STABLE_NEEDED" ] && break
    else
        stable=0
        prev="$cur"
    fi
done

if [ ! -d "$curpath/output/" ]; then
    mkdir -p "$curpath/output/"
fi

if [ -f "$LOGFILE" ]; then
    date "+%Y-%m-%d %H:%M:%S %a (%Z %z)" > "$LOGFILE"
    echo "======================"
    echo "$PROMPT" >> "$LOGFILE"
    echo "======================"
    echo "" >> "$LOGFILE"
fi

# 최종 화면(답변) 출력
echo "===== aiagent 응답 ====="
TM capture-pane -t "$SESSION" -p
# TM capture-pane -t "$SESSION" -p > "$curpath/output_tm_${SESSION}.txt"
TM capture-pane -t "$SESSION" -p >> "$LOGFILE"
echo "======================"

# trap 의 cleanup 으로 tmux 서버 종료됨
