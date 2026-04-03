#!/bin/bash
# claude-scroll-copymode.sh: Claude Code copy-mode에서 스크롤
# copy-mode 해제 → 이벤트 전송 → 화면 변화 감지 → copy-mode 재진입
#
# Usage:
#   claude-scroll-copymode.sh <up|down|pageup|pagedown|bottom> <pane-id>

DIR="${1:-up}"
TARGET="${2:-%}"
TERM_SEC=0.03
MAX_ITER=10

# SGR mouse wheel escape sequences
WHEEL_UP=$'\e[<64;1;1M'
WHEEL_DOWN=$'\e[<65;1;1M'
CTRL_HOME=$'\e[1;5H'
CTRL_END=$'\e[1;5F'
PAGE_UP=$'\e[5~'
PAGE_DOWN=$'\e[6~'

# 스크롤 중 플래그 (tmux pane option, 파일 IO 없음)
tmux set-option -t "$TARGET" -p @claude-scrolling 1
trap 'tmux set-option -t "$TARGET" -p -u @claude-scrolling 2>/dev/null' EXIT

# 스크롤 전 화면 캡처
before=$(tmux capture-pane -t "$TARGET" -p)

# copy-mode 해제
tmux send-keys -t "$TARGET" -X cancel

# 방향에 따라 이벤트 전송
case "$DIR" in
    up)
        tmux send-keys -t "$TARGET" "$WHEEL_UP" "$WHEEL_UP" "$WHEEL_UP" "$WHEEL_UP" "$WHEEL_UP"
        ;;
    down)
        tmux send-keys -t "$TARGET" "$WHEEL_DOWN" "$WHEEL_DOWN" "$WHEEL_DOWN" "$WHEEL_DOWN" "$WHEEL_DOWN"
        ;;
    pageup)
        tmux send-keys -t "$TARGET" "$PAGE_UP"
        ;;
    pagedown)
        tmux send-keys -t "$TARGET" "$PAGE_DOWN"
        ;;
    bottom)
        tmux send-keys -t "$TARGET" "$CTRL_HOME" "$CTRL_END"
        ;;
esac

# 화면 변화 대기 (폴링)
i=0
while [ "$i" -lt "$MAX_ITER" ]; do
    sleep "$TERM_SEC"
    after=$(tmux capture-pane -t "$TARGET" -p)
    [ "$before" != "$after" ] && break
    i=$((i + 1))
done

# copy-mode 재진입
tmux copy-mode -t "$TARGET"

exit 0
