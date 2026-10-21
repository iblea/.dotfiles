#!/bin/bash
# pane-slot.sh: pane 고정 번호(@pane_slot) 관리
#
# tmux pane index는 레이아웃 순서라 split 위치에 따라 기존 pane 번호가 밀린다.
# (1.1/1.2 에서 1.1을 split하면 기존 1.2가 1.3으로 밀림)
# 그래서 pane마다 고정 번호를 pane 옵션(@pane_slot)으로 붙여 index 대신 사용한다.
#   - 기존 pane 번호는 유지, 새 pane은 window 안에서 비어 있는 가장 작은 번호
#   - 번호는 window마다 독립 (1.2 / 2.2 공존 가능)
#   - 시작 번호는 pane-base-index
#   - 번호를 부여한 window를 @pane_slot_win에 기록, 다른 window에서 옮겨 온 pane
#     (join-pane/move-pane/break-pane)은 새 pane 취급
#
# Usage:
#   pane-slot.sh sync                       # 번호 없는/중복 pane에 빈 번호 부여 (hook에서 호출)
#   pane-slot.sh swap <src-pane-id> <N|.N|W.N>
#     N   : src의 window를 N번 window와 swap
#     .N  : src pane을 같은 window의 N번 pane과 swap
#     W.N : src pane을 W번 window의 N번 pane과 swap

sync_slots() {
    local base
    base="$(tmux show-options -gv pane-base-index 2>/dev/null)"

    # window별 index 순회: 이 window에서 부여된 유효/미중복 번호는 유지, 나머지는 빈 번호 중 가장 작은 값 부여
    # (linked window는 여러 session에 중복 출력되므로 pane_id 기준 1회만 처리)
    tmux list-panes -a -F '#{window_id}|#{pane_id}|#{@pane_slot}|#{@pane_slot_win}' 2>/dev/null |
    awk -F '|' -v base="${base:-0}" '
        $2 in seen { next }
        {
            seen[$2] = 1
            w = $1
            if (!(w in cnt)) wins[++nw] = w
            id[w, ++cnt[w]] = $2
            if ($4 == w && $3 ~ /^[0-9]+$/ && $3 >= base && !((w, $3 + 0) in used))
                used[w, $3 + 0] = 1
            else
                need[w, cnt[w]] = 1
        }
        END {
            for (i = 1; i <= nw; i++) {
                w = wins[i]
                s = base
                for (j = 1; j <= cnt[w]; j++) {
                    if (!((w, j) in need)) continue
                    while ((w, s) in used) s++
                    used[w, s] = 1
                    print w, id[w, j], s
                }
            }
        }' |
    while read -r win_id pane_id slot; do
        tmux set-option -p -t "$pane_id" @pane_slot "$slot" \; \
            set-option -p -t "$pane_id" @pane_slot_win "$win_id"
    done
}

swap_target() {
    local src="$1" input="$2" sess target slot dst src_win src_slot dst_win dst_slot
    sess="$(tmux display-message -p -t "$src" '#{session_id}')"

    # ".N" -> 현재 window의 N번 pane, "W.N" -> W번 window의 N번 pane
    case "$input" in
        .*)  target="$src"; slot="${input#.}" ;;
        *.*) target="${sess}:${input%%.*}"; slot="${input#*.}" ;;
        *)
            # "N" -> 현재 window를 N번 window와 swap (-d: 포커스는 현재 window를 따라감)
            tmux swap-window -d -s "$src" -t "${sess}:${input}" 2>/dev/null ||
                tmux display-message -d 2000 "swap failed: no such window [$input]"
            return
            ;;
    esac
    dst="$(tmux list-panes -t "$target" -F '#{@pane_slot} #{pane_id}' 2>/dev/null |
        awk -v s="$slot" 's != "" && $1 == s { n++; id = $2 } END { if (n == 1) print id }')"

    # 실패 시 run-shell이 view mode로 pane을 덮지 않도록 stderr 무시 + display-message로 알림
    if [ -z "$dst" ]; then
        tmux display-message -d 2000 "swap failed: no such pane [$input]"
        return
    fi

    read -r src_win src_slot <<< "$(tmux display-message -p -t "$src" '#{window_id} #{@pane_slot}')"
    read -r dst_win dst_slot <<< "$(tmux display-message -p -t "$dst" '#{window_id} #{@pane_slot}')"

    if [ "$src_win" = "$dst_win" ]; then
        # 같은 window: 번호가 pane을 따라 이동
        tmux swap-pane -s "$src" -t "$dst" 2>/dev/null
    else
        # 다른 window: 번호는 window마다 따로라서 들어온 pane이 나간 pane 번호를 이어받음
        # (sync hook이 중간 상태를 보지 않도록 swap과 번호 교환을 한 번의 명령 목록으로 처리)
        tmux swap-pane -s "$src" -t "$dst" \; \
            set-option -p -t "$src" @pane_slot "$dst_slot" \; set-option -p -t "$src" @pane_slot_win "$dst_win" \; \
            set-option -p -t "$dst" @pane_slot "$src_slot" \; set-option -p -t "$dst" @pane_slot_win "$src_win" 2>/dev/null
    fi
    [ $? -eq 0 ] || tmux display-message -d 2000 "swap failed: [$input]"
}

case "$1" in
    sync) sync_slots ;;
    swap) swap_target "$2" "$3" ;;
    *)
        echo "Usage: pane-slot.sh sync | swap <src-pane-id> <slot>" >&2
        exit 1
        ;;
esac
