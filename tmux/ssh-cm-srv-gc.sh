#!/bin/bash
# ssh-cm-srv-gc.sh: tmux 서버 종료 시 그 서버의 ssh ControlMaster 연결 정리
#
# ssh ControlPath = ~/.ssh/cm/%C-${TMUX_SRV}  (TMUX_SRV = tmux 서버 pid, 서버 단위 공유)
# 서버가 사라지면 소켓을 재사용할 pane이 없으므로 ControlPersist 대기 없이 마스터 즉시 종료
# 서버 종료(터미널 창 닫기, kill-server) 시에는 tmux hook이 실행되지 않아 서버마다 감시자로 처리
#   - 서버 단위 소켓        <hash>-<서버pid>
#   - 이전 pane 단위 소켓   <hash>-<서버pid>%<pane번호>  (ssh-cm-gc.sh 방식 잔여분)
#
# Usage:
#   ssh-cm-srv-gc.sh watch <tmux 서버 pid>    # 설정 로드 시 서버 종료 감시자 실행
#   ssh-cm-srv-gc.sh <tmux 서버 pid>          # 해당 서버 소켓 즉시 정리

if [ "$1" = watch ]; then
    # tmux job은 서버 종료 시 함께 kill되므로 job에서 분리 후 대기
    # wait-for는 서버 종료 외에 서버 시작 직후(attach 전, 붙은 클라이언트 0개)에도 반환
    #   → 서버가 아직 응답하면 재대기, 응답 없을 때만 정리
    #   (응답 확인은 전역 옵션 조회: list-clients 등은 세션 없는 시작 직후 "no current target" 실패)
    (
        while tmux wait-for ssh-cm-srv-gc-exit 2>/dev/null &&
              tmux show -gv default-shell >/dev/null 2>&1; do
            sleep 1
        done
        exec "$0" "$2"
    ) </dev/null >/dev/null 2>&1 &
    # 재로드 시 중복 생성 방지용 감시자 pid 기록 (tmux.aiagent.conf에서 생존 확인)
    tmux set -g @ssh_cm_srv_gc_watch "$!"
    exit 0
fi

srv=$1
# 빈 값/비정상 값이면 glob이 넓어지므로 중단
case $srv in ''|*[!0-9]*) exit 1 ;; esac

for sock in "$HOME"/.ssh/cm/*-"$srv" "$HOME"/.ssh/cm/*-"$srv"%*; do
    [ -S "$sock" ] || continue
    # -S 경로도 ssh의 % 토큰 확장 대상 (%25 → "unknown key %2") → %% 이스케이프
    ssh -S "${sock//\%/%%}" -O exit _ >/dev/null 2>&1
done
