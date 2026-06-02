#!/bin/bash
# goto-window-pane.sh: window/pane으로 이동 (prefix + C-f command-prompt에서 호출)
#
# 입력 표기법은 showtmuxpane / sendtmuxpane / tmuxaddir 과 동일하다.
#   "2"     -> 2번 윈도우 1번 페인 (pane-base-index)
#   "2 2"   -> 2번 윈도우 2번 페인 (공백 구분)
#   "2.2"   -> 2번 윈도우 2번 페인
#   ".2"    -> 현재(호출) 윈도우 2번 페인
#
# Usage:
#   goto-window-pane.sh "<input>" [<src-pane-id>]

input="${1:-}"
src_pane="${2:-$TMUX_PANE}"

# 앞뒤 공백 제거 후 내부 공백(연속 포함)을 점 하나로 변환 ("2 2" -> "2.2")
input="$(printf '%s' "$input" | sed 's/^ *//; s/ *$//' | tr -s ' ' '.')"

# 빈 입력이면 조용히 종료
[ -z "$input" ] && exit 0

# Pane Argument 파싱: <window>.<pane> / .<pane> / <window>
case "$input" in
    .*)
        # ".pane" -> 호출 페인($src_pane)의 윈도우 번호를 앞에 채움
        # 타겟 없는 '#I'는 "활성 윈도우"라, 프롬프트 입력 후 윈도우가 바뀌면
        # 엉뚱한 곳을 잡으므로 호출 시점의 pane_id 기준으로 고정한다.
        if [ -n "$src_pane" ]; then
            win="$(tmux display-message -p -t "$src_pane" '#I')"
        else
            win="$(tmux display-message -p '#I')"
        fi
        target="${win}${input}"
        ;;
    *.*)
        # "window.pane" -> 그대로 사용
        win="${input%%.*}"
        target="$input"
        ;;
    *)
        # "window"만 (점 없음) -> 첫 페인 명시 (2 -> 2.<pane-base-index>)
        win="$input"
        pane_base="$(tmux show-options -gv pane-base-index 2>/dev/null)"
        target="${input}.${pane_base:-0}"
        ;;
esac

# 윈도우 존재 확인
if ! tmux list-windows -F '#I' | grep -qx "$win"; then
    tmux display-message "goto: no such window '$win'"
    exit 0
fi

# 페인 존재 확인 (없는 페인이면 윈도우 전환도 하지 않아 원자적으로 동작)
if ! tmux list-panes -t "$win" -F '#I.#P' 2>/dev/null | grep -qx "$target"; then
    tmux display-message "goto: no such pane '$target'"
    exit 0
fi

# 이동: 윈도우 선택 후 페인 선택
tmux select-window -t "$win"
tmux select-pane -t "$target"
