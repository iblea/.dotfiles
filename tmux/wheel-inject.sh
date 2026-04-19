#!/usr/bin/env bash
# wheel-inject.sh: 타겟 pane에 SGR mouse wheel event 주입
#
# 사용법:
#   wheel-inject.sh <up|down|left|right> [pane-id]
#
# 좌표는 타겟 pane의 중앙으로 자동 계산 (hit-test 통과 목적).

set -u

DIR="${1:-}"
TARGET="${2:-}"

case "$DIR" in
  up)    CODE=64 ;;
  down)  CODE=65 ;;
  left)  CODE=66 ;;
  right) CODE=67 ;;
  *)
    echo "usage: $0 <up|down|left|right> [pane-id]" >&2
    exit 1
    ;;
esac

if [ -n "$TARGET" ]; then
  W=$(tmux display -t "$TARGET" -p '#{pane_width}')
  H=$(tmux display -t "$TARGET" -p '#{pane_height}')
  CX=$(( W / 2 ))
  CY=$(( H / 2 ))
  tmux send-keys -t "$TARGET" -l "$(printf '\033[<%d;%d;%dM' "$CODE" "$CX" "$CY")"
else
  W=$(tmux display -p '#{pane_width}')
  H=$(tmux display -p '#{pane_height}')
  CX=$(( W / 2 ))
  CY=$(( H / 2 ))
  tmux send-keys -l "$(printf '\033[<%d;%d;%dM' "$CODE" "$CX" "$CY")"
fi