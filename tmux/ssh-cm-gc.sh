#!/bin/bash
# ssh-cm-gc.sh: 종료된 tmux pane의 ssh ControlMaster 연결 정리
#
# [비활성] ControlPath 서버 단위 공유(%C-${TMUX_SRV}) 전환으로 tmux.aiagent.conf hook 주석 처리
#          서버 종료 시 정리는 ssh-cm-srv-gc.sh 담당, pane 단위로 되돌릴 때 hook 주석 해제
#
# ssh ControlPath = ~/.ssh/cm/%C-${TMUX_SRV}${TMUX_PANE}  (TMUX_SRV = tmux 서버 pid)
# 소켓 주인 pane이 사라지면 재사용될 일이 없으므로 ControlPersist 대기 없이 마스터 즉시 종료
# 소켓 이름 끝의 <서버pid>%<pane번호>를 현재 tmux 상태와 대조
#   - 이 서버 소켓인데 pane 없음      → 마스터 종료
#   - 소켓 주인 tmux 서버가 이미 죽음 → 마스터 종료
#   - 다른 살아있는 tmux 서버 소켓    → 유지
#
# Usage:
#   ssh-cm-gc.sh <tmux 서버 pid>          # pane/window 종료 hook에서 #{pid} 전달
#   ssh-cm-gc.sh watch <tmux 서버 pid>    # 서버 종료 감시 (서버 종료 시에는 hook 미실행)

if [ "$1" = watch ]; then
    # tmux job은 서버 종료 시 함께 kill되므로 job에서 분리 후 대기
    # 서버가 종료되면 wait-for 연결이 끊겨 반환
    ( tmux wait-for ssh-cm-gc-exit; exec "$0" "$2" ) </dev/null >/dev/null 2>&1 &
    exit 0
fi

srv=$1
alive=" $(tmux list-panes -a -F '#{pane_id}' 2>/dev/null | tr '\n' ' ') "

for sock in "$HOME"/.ssh/cm/*-*%*; do
    [ -S "$sock" ] || continue
    tag=${sock##*-}    # <서버pid>%<pane번호>
    s=${tag%%\%*}
    n=${tag#*%}
    # 형식이 다른 소켓(마스터 생성 중 임시 소켓 등)은 제외
    case $s in ''|*[!0-9]*) continue ;; esac
    case $n in ''|*[!0-9]*) continue ;; esac

    if [ "$s" = "$srv" ]; then
        case $alive in *" %$n "*) continue ;; esac    # 살아있는 pane
    elif kill -0 "$s" 2>/dev/null; then
        continue                                      # 다른 tmux 서버 소유
    fi
    # -S 경로도 ssh의 % 토큰 확장 대상 (%25 → "unknown key %2") → %% 이스케이프
    ssh -S "${sock//\%/%%}" -O exit _ >/dev/null 2>&1
done
