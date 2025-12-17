#!/bin/bash
# vim/nvim/fzf 실행 감지 스크립트
# tmux if-shell에서 사용
ps -o state= -o comm= -t "$(tmux display-message -p '#{pane_tty}')" \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'
