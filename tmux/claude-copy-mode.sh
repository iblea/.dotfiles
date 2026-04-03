#!/bin/bash
# claude-copy-mode.sh: Claude Code pane에서 copy-mode 진입/취소
# check_claude_state 폴링으로 실제 상태 변화를 감지
# copy-mode 종료는 pane-mode-changed hook으로 자동 감지
#
# Claude Code 화면 상태별 분기:
#   기본 상태            → C-o → [ → copy-mode
#   ctrl+o 상태 (scroll 안내 있음) → [ → copy-mode
#   ctrl+o+[ 상태 (transcript만)  → copy-mode
#
# Usage:
#   claude-copy-mode.sh enter <pane-id>
#   claude-copy-mode.sh toggle <pane-id>
#   claude-copy-mode.sh exit-hook <orig-pane-id> [hook-pane-id] [hook-pane-mode]

MODE="${1:-enter}"

TERM_SEC=0.03

# Claude Code 화면 상태 판별 (마지막 3라인 기준)
# return: 0=ctrl+o 상태, 1=ctrl+o+[ 상태, 2=기본 상태
check_claude_state() {
    local target=$1
    local merged
    merged=$(tmux capture-pane -t "$target" -p | tail -3 | tr '\n' ' ')

    if echo "$merged" | grep -qF "Showing detailed transcript" && \
       echo "$merged" | grep -qF "ctrl+o to toggle" && \
       echo "$merged" | grep -qF "scroll"; then
        return 0  # ctrl+o 상태 (scroll 안내 표시됨)
    elif echo "$merged" | grep -qF "Showing detailed transcript" && \
         echo "$merged" | grep -qF "ctrl+o to toggle"; then
        return 1  # ctrl+o+[ 상태 (transcript 표시만)
    else
        return 2  # 기본 상태
    fi
}

# 현재 상태에서 벗어날 때까지 폴링
# args: <target> <current_state> [max_iter]
wait_state_change() {
    local target=$1
    local current=$2
    local max=${3:-30}
    local i=0

    while [ "$i" -lt "$max" ]; do
        sleep "$TERM_SEC"
        check_claude_state "$target"
        [ $? -ne "$current" ] && return 0
        i=$((i + 1))
    done
    return 1
}

case "$MODE" in
    enter)
        TARGET="${2:-%}"

        check_claude_state "$TARGET"
        state=$?

        if [ "$state" -eq 0 ]; then
            # ctrl+o 상태 → [ 보내고 상태 변화 대기
            tmux send-keys -t "$TARGET" '['
            wait_state_change "$TARGET" 0
            tmux copy-mode -t "$TARGET"
        elif [ "$state" -eq 1 ]; then
            # ctrl+o+[ 상태 → 바로 copy-mode
            tmux copy-mode -t "$TARGET"
        else
            # 기본 상태 → C-o 전송 → 상태 변화 대기
            tmux send-keys -t "$TARGET" C-o
            wait_state_change "$TARGET" 2
            # [ 전송 → 상태 변화 대기
            tmux send-keys -t "$TARGET" '['
            wait_state_change "$TARGET" 0
            tmux copy-mode -t "$TARGET"
        fi

        # pane-mode-changed hook 설정 (copy-mode 종료 시 자동 처리)
        tmux set-hook -w pane-mode-changed \
            "run-shell -b \"$HOME/.dotfiles/tmux/claude-copy-mode.sh exit-hook $TARGET #{pane_id} #{pane_mode}\""
        ;;
    toggle)
        # copy-mode 내에서 C-o 토글 (hook 간섭 방지)
        TARGET="${2:-%}"
        # hook 임시 해제 (cancel 시 exit-hook 발동 방지)
        tmux set-hook -uw pane-mode-changed 2>/dev/null
        # cancel 후 현재 상태 확인
        tmux send-keys -t "$TARGET" -X cancel
        check_claude_state "$TARGET"
        prev_state=$?

        # C-o 전송 → 상태 변화 대기
        tmux send-keys -t "$TARGET" C-o
        wait_state_change "$TARGET" "$prev_state"

        # 상태 체크: ctrl+o 상태면 [ 도 전송
        check_claude_state "$TARGET"
        state=$?
        if [ "$state" -eq 0 ]; then
            tmux send-keys -t "$TARGET" '['
            wait_state_change "$TARGET" 0
        fi

        # copy-mode 재진입
        tmux copy-mode -t "$TARGET"
        # hook 재설정
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

        # hook 해제
        tmux set-hook -uw pane-mode-changed

        # cancel 후 화면 상태 확인 → transcript 모드이면 C-o로 빠져나가기
        MERGED=$(tmux capture-pane -t "$ORIG_TARGET" -p | tail -3 | tr '\n' ' ')
        if echo "$MERGED" | grep -qF "Showing detailed transcript" && \
           echo "$MERGED" | grep -qF "ctrl+o to toggle"; then
            tmux send-keys -t "$ORIG_TARGET" C-o
        fi
        ;;
esac

exit 0
