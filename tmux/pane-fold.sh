#!/bin/bash
# pane-fold.sh: pane 접기(숨기기) 토글
#
# tmux에는 특정 pane만 숨기는 기능이 없어서 pane을 1줄/1칸으로 축소하고
# pane 옵션 @folded 로 표시, pane 이동 시 접힌 pane은 건너뜀
#   - 접는 방향은 레이아웃 트리 기준: 같은 분할 안에 보이는(펼친 pane이 있는) 형제가 있는 방향으로 축소
#     (같은 열이 전부 접히면 열 전체를 너비 1칸으로, [1|2]/3 에서 2를 접으면 2만 너비 1칸으로)
#   - 접힌 pane이 없을 때의 레이아웃을 window 옵션 @fold_base(+pane 목록 @fold_base_ids)에 저장,
#     접기/펼치기마다 @fold_base 복원 후 현재 접힌 pane 전체를 다시 접음 (순서와 무관하게 원래 크기로 복원)
#   - 접힌 동안 pane 구성이 바뀌면(split/kill) @fold_base 대신 접은 역순으로 그 pane과 이웃을 균등 배치
#     (원래 크기로 키우면 바로 옆 pane이 1칸으로 눌리므로 select-layout -E 사용)
#   - 접힌 동안 펼친 pane 크기를 수동 조절해도 다음 접기/펼치기에서 @fold_base 크기로 돌아감
#   - 마우스 클릭/goto/방향키(C-s 방향키)/last-pane 으로는 접힌 pane에 들어갈 수 있음 (접힌 상태 유지)
#   - @folded 값: 1 = 접기(크기 축소), 2 = soft 접기(크기 변경 없이 pane 전환 시 건너뛰기만)
#     soft 접힌 pane은 접기/펼치기 모두 resize 없음, @fold_base 복원/재접기 대상에서도 제외
#
# Usage:
#   pane-fold.sh toggle <pane-id> [soft] # 접기 (접힌 pane이면 펼치기), 접은 뒤 다음 pane으로 이동, soft = 크기 유지
#   pane-fold.sh unfold-all <pane-id>   # pane이 속한 window의 접힌 pane 전부 펼치기
#   pane-fold.sh goto <pane-id>         # 접힌 pane 순회: 보이는 pane -> 접힌1 -> 접힌2 -> ... -> 출발 pane
#   pane-fold.sh move <next|prev> <pane-id>  # 접힌 pane을 건너뛰고 다음/이전 pane 선택
#   pane-fold.sh join <src-pane-id> <dst-pane-id> [h|j|k|l] [f]  # src를 dst 기준 방향으로 이동 (접힌 pane은 접힌 채로)
#
# run-shell은 0이 아닌 종료 코드를 pane에 덮어 표시하므로 실패 시에도 0으로 종료

# $1 기준 $2(next|prev) 방향으로 접히지 않은 첫 pane id 출력 (없으면 출력 없음)
visible_target() {
    tmux list-panes -t "$1" -F '#{pane_id} #{?@folded,1,0}' 2>/dev/null |
    awk -v cur="$1" -v dir="$2" '
        { id[NR] = $1; folded[NR] = $2 + 0; if ($1 == cur) c = NR }
        END {
            if (!c) exit
            for (k = 1; k < NR; k++) {
                i = (dir == "next") ? (c - 1 + k) % NR + 1 : (c - 1 - k + NR) % NR + 1
                if (folded[i] == 0) { print id[i]; exit }
            }
        }'
}

# 레이아웃 $1 과 접힌 pane 목록 $2 로 pane별 접는 방향 출력 ("<pane-id> <x|y>")
# leaf에서 위로 올라가며 보이는 형제가 있는 첫 분할의 방향 ({ } 좌우 분할 -> x, [ ] 상하 분할 -> y)
fold_dirs() {
    awk -v layout="$1" -v list="$2" '
        function num(   v) {
            v = ""
            while (substr(s, pos, 1) ~ /[0-9]/) { v = v substr(s, pos, 1); pos++ }
            return v
        }
        # cell: WxH,X,Y 뒤에 ,ID (leaf) 또는 {cells} / [cells]
        function parse(parent,   node, c) {
            node = ++n; par[node] = parent
            if (parent) kid[parent, ++nk[parent]] = node
            num(); pos++; num(); pos++; num(); pos++; num()
            c = substr(s, pos, 1)
            if (c == ",") {
                pos++; pane[node] = "%" num(); node_of[pane[node]] = node
            } else {
                typ[node] = (c == "{") ? "x" : "y"
                do { pos++; parse(node) } while (substr(s, pos, 1) == ",")
                pos++
            }
        }
        BEGIN {
            s = substr(layout, index(layout, ",") + 1); pos = 1
            parse(0)
            cnt = split(list, f, " ")
            for (i = 1; i <= cnt; i++) folded[f[i]] = 1
            # 자식 번호가 부모보다 크므로 역순으로 보이는 여부 전파
            for (i = n; i >= 1; i--) {
                if (i in pane) vis[i] = !(pane[i] in folded)
                if (vis[i] && par[i]) vis[par[i]] = 1
            }
            for (i = 1; i <= cnt; i++) {
                node = node_of[f[i]]; dir = ""
                while (node && par[node] && dir == "") {
                    m = par[node]
                    for (k = 1; k <= nk[m]; k++)
                        if (kid[m, k] != node && vis[kid[m, k]]) { dir = typ[m]; break }
                    node = m
                }
                if (dir != "") print f[i], dir
            }
        }'
}

# window의 접힘 상태를 @folded 기준으로 다시 적용
apply() {
    local win base base_ids ids layout folded seq
    win="$(tmux display-message -p -t "$1" '#{window_id}' 2>/dev/null)"
    base="$(tmux show-options -wqv -t "$win" @fold_base 2>/dev/null)"
    base_ids="$(tmux show-options -wqv -t "$win" @fold_base_ids 2>/dev/null)"
    ids="$(tmux list-panes -t "$win" -F '#{pane_id}' 2>/dev/null | tr '\n' ' ')"

    # 1. 펼친 상태로 복원: pane 구성이 그대로면 @fold_base, 바뀌었으면 접은 역순으로 그 pane과 이웃 균등 배치
    if [ -z "$base" ] || [ "$ids" != "$base_ids" ] || ! tmux select-layout -t "$win" "$base" 2>/dev/null; then
        tmux list-panes -t "$win" -F '#{pane_id} #{?@fold_dir,1,0} #{?@fold_seq,#{@fold_seq},0}' 2>/dev/null |
        awk '$2 == 1' | sort -k3 -rn |
        while read -r id _; do
            tmux select-layout -E -t "$id" 2>/dev/null
        done
    fi
    tmux list-panes -t "$win" -F '#{pane_id}' 2>/dev/null | while read -r id; do
        tmux set-option -pu -t "$id" @fold_dir \; set-option -pu -t "$id" @fold_seq 2>/dev/null
    done

    # 2. 접힌 pane이 없으면 기준 레이아웃 삭제 (soft 접힌 pane(@folded=2)은 제외)
    folded="$(tmux list-panes -t "$win" -F '#{pane_id} #{@folded}' 2>/dev/null | awk '$2 == 1 { printf "%s ", $1 }')"
    if [ -z "$folded" ]; then
        tmux set-option -wu -t "$win" @fold_base \; set-option -wu -t "$win" @fold_base_ids \; \
            set-option -wu -t "$win" @fold_return 2>/dev/null
        return
    fi

    # 3. 펼친 상태를 기준 레이아웃으로 저장 후 접기
    layout="$(tmux display-message -p -t "$win" '#{window_layout}' 2>/dev/null)"
    tmux set-option -w -t "$win" @fold_base "$layout" \; \
        set-option -w -t "$win" @fold_base_ids "$ids" 2>/dev/null
    seq=0
    fold_dirs "$layout" "$folded" | while read -r id dir; do
        seq=$((seq + 1))
        tmux set-option -p -t "$id" @fold_dir "$dir" \; \
            set-option -p -t "$id" @fold_seq "$seq" \; \
            resize-pane -t "$id" "-$dir" 1 2>/dev/null
    done
}

toggle() {
    local pane="$1" mode="$2" dst cur
    cur="$(tmux display-message -p -t "$pane" '#{@folded}' 2>/dev/null)"
    if [ -n "$cur" ]; then
        tmux set-option -pu -t "$pane" @folded 2>/dev/null
        # soft 접힘 해제는 resize 없음
        [ "$cur" = 1 ] && apply "$pane"
        return
    fi

    # 접은 뒤 포커스를 넘길 pane이 없으면 (pane 1개 / 나머지 전부 접힘) 접지 않음
    dst="$(visible_target "$pane" next)"
    if [ -z "$dst" ]; then
        tmux display-message -d 1500 "fold: no other visible pane"
        return
    fi
    if [ "$mode" = soft ]; then
        tmux set-option -p -t "$pane" @folded 2 2>/dev/null
    else
        tmux set-option -p -t "$pane" @folded 1 2>/dev/null
        apply "$pane"
    fi
    tmux select-pane -t "$dst" 2>/dev/null
}

unfold_all() {
    tmux list-panes -t "$1" -F '#{pane_id}' 2>/dev/null | while read -r id; do
        tmux set-option -pu -t "$id" @folded 2>/dev/null
    done
    apply "$1"
}

move() {
    local dst
    dst="$(visible_target "$2" "$1")"
    if [ -n "$dst" ]; then
        tmux select-pane -t "$dst" 2>/dev/null
    fi
}

# 보이는 pane에서 누르면 첫 접힌 pane으로 (출발 pane을 window 옵션 @fold_return에 기억)
# 접힌 pane에서 누르면 다음 접힌 pane, 마지막이면 출발 pane으로 복귀
# (출발 pane이 없거나 닫혔거나 그 사이 접혔으면 다음 보이는 pane)
goto() {
    local pane="$1" win cur first after ret dst
    win="$(tmux display-message -p -t "$pane" '#{window_id}' 2>/dev/null)"
    read -r cur first after <<< "$(tmux list-panes -t "$win" -F '#{pane_id} #{?@folded,1,0}' 2>/dev/null | awk -v p="$pane" '
        $1 == p { cur = $2 }
        $2 == 1 && first == "" { first = $1 }
        $2 == 1 && seen && after == "" { after = $1 }
        $1 == p { seen = 1 }
        END { print (cur == "" ? 0 : cur), first, after }')"

    if [ -z "$first" ]; then
        tmux display-message -d 1500 "fold: no hidden pane"
        return
    fi
    if [ "$cur" != 1 ]; then
        tmux set-option -w -t "$win" @fold_return "$pane" \; select-pane -t "$first" 2>/dev/null
        return
    fi
    if [ -n "$after" ]; then
        tmux select-pane -t "$after" 2>/dev/null
        return
    fi
    ret="$(tmux show-options -wqv -t "$win" @fold_return 2>/dev/null)"
    if [ -n "$ret" ] && tmux list-panes -t "$win" -F '#{pane_id} #{?@folded,1,0}' 2>/dev/null | grep -qx "$ret 0"; then
        dst="$ret"
    else
        dst="$(visible_target "$pane" next)"
    fi
    if [ -n "$dst" ]; then
        tmux select-pane -t "$dst" 2>/dev/null
    fi
}

# src pane을 dst pane 기준 $3 방향(h/j/k/l = 왼쪽/아래/위/오른쪽, 기본 아래)으로 이동, 접힌 상태 유지
#   $4 = "f": dst pane 대신 dst window 전체 기준 가장자리로 이동 (move-pane -f)
#   move-pane은 dst를 반으로 나눠 넣을 뿐 @folded/@fold_base를 모르므로
#   양쪽 window 펼침 -> 이동 -> 접혀 있던 pane 다시 접기 순으로 처리
#   (펼친 상태에서 이동하므로 이동 후 펼친 레이아웃이 @fold_base로 새로 저장됨)
join() {
    local src="$1" dst="$2" dir="$3" full="$4" flags src_win src_folded src_panes dst_win wins folded w id err moved=0
    case "$dir" in
        h) flags="-hb" ;;
        l) flags="-h" ;;
        k) flags="-vb" ;;
        *) flags="-v" ;;
    esac
    [ "$full" = f ] && flags="${flags}f"

    read -r src_win src_folded src_panes <<< "$(tmux display-message -p -t "$src" '#{window_id} #{?@folded,1,0} #{window_panes}' 2>/dev/null)"
    dst_win="$(tmux display-message -p -t "$dst" '#{window_id}' 2>/dev/null)"
    if [ -z "$src_win" ] || [ -z "$dst_win" ] || [ "$src" = "$dst" ]; then
        tmux display-message -d 2000 "move failed: invalid pane [$src -> $dst]"
        return
    fi

    # 보이는 pane을 다른 window로 빼면 출발 window에 접힌 pane만 남는 경우 차단 (toggle과 같은 조건)
    if [ "$src_win" != "$dst_win" ] && [ "$src_folded" = 0 ] && [ "$src_panes" -gt 1 ] &&
        [ -z "$(visible_target "$src" next)" ]; then
        tmux display-message -d 2000 "move failed: no other visible pane in source window"
        return
    fi

    wins="$src_win"
    [ "$dst_win" != "$src_win" ] && wins="$wins $dst_win"

    # 1. 양쪽 window의 접힌 pane 기억 후 펼침 (soft 접힌 pane은 크기 변경이 없으므로 그대로 둠)
    folded="$(for w in $wins; do
        tmux list-panes -t "$w" -F '#{pane_id} #{@folded}' 2>/dev/null
    done | awk '$2 == 1 { printf "%s ", $1 }')"
    if [ -n "$folded" ]; then
        for id in $folded; do
            tmux set-option -pu -t "$id" @folded 2>/dev/null
        done
        for w in $wins; do
            apply "$w"
        done
    fi

    # 2. 이동 (실패해도 3에서 원래 상태로 다시 접힘)
    if err="$(tmux move-pane "$flags" -s "$src" -t "$dst" 2>&1)"; then
        moved=1
    else
        tmux display-message -d 2000 "move failed: $err"
    fi

    # 3. 기억한 pane 다시 접기
    #    (pane이 1개뿐이던 출발 window는 이동 후 사라짐, 빈 target은 현재 window로 해석되므로 존재 확인)
    if [ -n "$folded" ]; then
        for id in $folded; do
            tmux set-option -p -t "$id" @folded 1 2>/dev/null
        done
        for w in $wins; do
            tmux list-panes -t "$w" >/dev/null 2>&1 && apply "$w"
        done
    fi

    # 4. 옮긴 pane이 접혀 있으면 포커스를 보이는 pane으로 (dst 우선, dst도 접혔으면 다음 보이는 pane)
    if [ "$moved" = 1 ] && [ "$(tmux display-message -p -t "$src" '#{?@folded,1,0}' 2>/dev/null)" = 1 ]; then
        if [ "$(tmux display-message -p -t "$dst" '#{?@folded,1,0}' 2>/dev/null)" = 0 ]; then
            tmux select-pane -t "$dst" 2>/dev/null
        else
            move next "$src"
        fi
    fi
}

case "$1" in
    toggle) toggle "$2" "$3" ;;
    unfold-all) unfold_all "$2" ;;
    goto) goto "$2" ;;
    move) move "$2" "$3" ;;
    join) join "$2" "$3" "$4" "$5" ;;
    *)
        echo "Usage: pane-fold.sh toggle <pane-id> [soft] | unfold-all <pane-id> | goto <pane-id> | move <next|prev> <pane-id> | join <src-pane-id> <dst-pane-id> [h|j|k|l] [f]" >&2
        exit 1
        ;;
esac
exit 0
