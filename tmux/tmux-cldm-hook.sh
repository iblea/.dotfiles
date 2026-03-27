#!/bin/bash
# SSH 환경에서 cldm이 보낸 OSC 트리거를 감지하여 로컬 tmux 윈도우를 1번으로 이동
# tmux pane-title-changed hook에서 호출됨
# 사용법: tmux-cldm-hook.sh <pane_title> <pane_id>

PANE_TITLE="$1"
PANE_ID="$2"

# cleanup 트리거: Claude Code 종료 후 @is_claude_code 해제
if [ "$PANE_TITLE" = "__CLDM_CLEANUP__" ]; then
    tmux set-option -pu -t "$PANE_ID" @is_claude_code 2>/dev/null
    exit 0
fi

# swap 트리거 패턴이 아니면 즉시 종료
[ "$PANE_TITLE" = "__CLDM_SWAP_WIN1__" ] || exit 0

# 해당 pane이 속한 윈도우 인덱스
WIN_IDX=$(tmux display-message -t "$PANE_ID" -p '#{window_index}' 2>/dev/null)
if [ -z "$WIN_IDX" ] || [ "$WIN_IDX" = "1" ]; then
    exit 0
fi

# 1번 윈도우가 이미 claude_code인지 확인
_win1_panes=$(tmux display-message -t :1 -p '#{window_panes}' 2>/dev/null)
if [ "${_win1_panes:-0}" -gt 1 ] 2>/dev/null; then
    _win1_is_claude=$(tmux show-option -pqv -t :1.1 @is_claude_code 2>/dev/null)
else
    _win1_is_claude=$(tmux show-option -pqv -t :1 @is_claude_code 2>/dev/null)
fi
[ "$_win1_is_claude" = "1" ] && exit 0

# 윈도우를 1번으로 이동 (swap)
_i=$WIN_IDX
while [ "$_i" -gt 1 ]; do
    _prev=$((_i - 1))
    tmux swap-window -s ":${_i}" -t ":${_prev}" 2>/dev/null
    _i=$_prev
done

tmux select-window -t :1 2>/dev/null
tmux set-option -p -t "$PANE_ID" @is_claude_code 1 2>/dev/null
