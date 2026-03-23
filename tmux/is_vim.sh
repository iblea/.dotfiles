#!/bin/bash
# vim/nvim/fzf 실행 감지 스크립트
# tmux if-shell에서 사용

# 1. pane_title로 SSH 너머 vim 감지
tmux display-message -p '#{pane_title}' \
    | grep -iqE '(^|/)(view|l?n?vim?x?|fzf)(diff)?(\s|$)' && exit 0

# 2. pane_current_command로 감지
tmux display-message -p '#{pane_current_command}' \
    | grep -iqE '^(view|l?n?vim?x?|fzf)(diff)?$' && exit 0

# 3. 로컬 프로세스 확인
ps -o state= -o comm= -t "$(tmux display-message -p '#{pane_tty}')" \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$' && exit 0

exit 1
