#!/bin/bash
# Claude Code 실행 감지 스크립트
# tmux if-shell에서 사용

# 1. @is_claude_code pane 옵션 체크 (cldm hook에서 설정됨)
[ "$(tmux show-option -pqv @is_claude_code 2>/dev/null)" = "1" ] && exit 0

# 2. pane_title로 SSH 너머 Claude Code 감지
tmux display-message -p '#{pane_title}' \
    | grep -iqE '(^|[/ ])claude( |$)' && exit 0

# 3. pane_current_command로 감지 (로컬)
tmux display-message -p '#{pane_current_command}' \
    | grep -iqE '^claude$' && exit 0

# 4. 로컬 프로세스 확인 (pane tty에서 claude 프로세스)
ps -o state= -o comm= -t "$(tmux display-message -p '#{pane_tty}')" \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?claude$' && exit 0

exit 1
