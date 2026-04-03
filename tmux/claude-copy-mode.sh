#!/bin/bash
# claude-copy-mode.sh: Claude Code pane에서 copy-mode 진입/취소
# 고정 sleep 대신 화면 캡처 폴링으로 화면 안정화를 동적 감지
# copy-mode 종료는 pane-mode-changed hook으로 자동 감지
#
# Usage:
#   claude-copy-mode.sh enter <pane-id>
#     → C-o → [ → copy-mode 진입 + pane-mode-changed hook 설정
#   claude-copy-mode.sh exit-hook <orig-pane-id> [hook-pane-id] [hook-pane-mode]
#     → copy-mode 종료 감지 시 C-o 전송 + hook 해제

MODE="${1:-enter}"

TERM_SEC=0.03

# 화면 캡처 폴링으로 안정화 대기
# args: <target> <threshold> <max_iter> <min_wait_sec>
# return: 0=안정화됨, 1=타임아웃
wait_stable() {
    local target=$1
    local threshold=$2
    local max=$3
    local min_wait=${4:-0}
    local stable=0
    local i=0

    local prev
    prev=$(tmux capture-pane -t "$target" -p | cksum)

    [ "$min_wait" != "0" ] && sleep "$min_wait"

    while [ "$i" -lt "$max" ]; do
        curr=$(tmux capture-pane -t "$target" -p | cksum)
        if [ "$curr" = "$prev" ]; then
            stable=$((stable + 1))
            [ "$stable" -ge "$threshold" ] && return 0
        else
            stable=0
        fi
        prev="$curr"
        i=$((i + 1))
        sleep "$TERM_SEC"
    done
    return 1
}

case "$MODE" in
    enter)
        TARGET="${2:-%}"
        # Phase 1: C-o 전송 후 화면 안정화 대기
        tmux send-keys -t "$TARGET" C-o
        wait_stable "$TARGET" 2 10 0.05
        # Phase 2: [ 전송 후 화면 안정화 대기
        tmux send-keys -t "$TARGET" '['
        wait_stable "$TARGET" 2 10 0.05
        # Phase 3: copy-mode 진입
        tmux copy-mode -t "$TARGET"
        # Phase 4: pane-mode-changed hook 설정 (copy-mode 종료 시 자동으로 C-o 전송)
        tmux set-hook -w pane-mode-changed \
            "run-shell -b \"$HOME/.dotfiles/tmux/claude-copy-mode.sh exit-hook $TARGET #{pane_id} #{pane_mode}\""
        ;;
    exit-hook)
        ORIG_TARGET="${2:-%}"
        HOOK_PANE="${3:-}"
        HOOK_MODE="${4:-}"

        # 원래 Claude Code pane이 아니면 무시
        [ -n "$HOOK_PANE" ] && [ "$HOOK_PANE" != "$ORIG_TARGET" ] && exit 0
        # 아직 copy-mode이면 무시 (진입 시에도 hook 발동됨)
        [ -n "$HOOK_MODE" ] && exit 0

        # hook 해제 + C-o 전송
        tmux set-hook -uw pane-mode-changed
        tmux send-keys -t "$ORIG_TARGET" C-o
        ;;
esac

exit 0
