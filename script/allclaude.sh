#!/usr/bin/env bash
# 모든 디렉토리의 Claude Code 세션을 fzf로 선택 후 해당 디렉토리에서 resume
set -u

# 부모 쉘의 CLAUDE_CONFIG_DIR 상속 (미설정 시 ~/.claude), resume하는 claude에도 동일 값 전달
export CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PROJECTS_DIR="$CLAUDE_CONFIG_DIR/projects"

for cmd in fzf jq claude; do
    command -v "$cmd" >/dev/null || { echo "allclaude: $cmd 없음" >&2; exit 1; }
done

# 파일별 mtime (GNU stat 우선, 실패 시 BSD stat)
mtimes() {
    stat -c '%n:mtime:%Y' "$@" 2>/dev/null || stat -f '%N:mtime:%m' "$@"
}

# 모든 행을 "파일경로:값" 형태로 모아 jq 한 번으로 세션별 집계
list_sessions() {
    local files=("$PROJECTS_DIR"/*/*.jsonl)
    [ -e "${files[0]}" ] || return 0
    {
        mtimes "${files[@]}"
        LC_ALL=C grep -m1 -o -H '"cwd":"[^"]*"' "${files[@]}"
        LC_ALL=C grep -H -E '"type":"(agent-name|ai-title|last-prompt)"' "${files[@]}"
    } | jq -rRn --arg home "$HOME" '
        # 터미널 표시 폭 (한글 등 CJK는 2칸)
        def cw: if . >= 4352 then 2 else 1 end;
        def width: explode | map(cw) | add // 0;
        # 폭 $n 초과 시 앞부분을 ...로 생략 (뒤에서부터 폭 기준으로 채움)
        def fit($n):
            if width <= $n then . else
                "..." + (explode | reverse
                    | reduce .[] as $c ({w: 0, out: [], full: false};
                        if .full or .w + ($c | cw) > $n - 3 then .full = true
                        else .w += ($c | cw) | .out += [$c] end)
                    | .out | reverse | implode)
            end;
        def pad($n): . + " " * ($n - width + 2);

        reduce (inputs | capture("^(?<f>[^:]+):(?<v>.*)$")) as $l ({};
            if ($l.v | startswith("mtime:")) then
                .[$l.f].mtime = ($l.v[6:] | tonumber)
            elif ($l.v | startswith("\"cwd\":")) then
                .[$l.f].cwd = (("{\($l.v)}" | fromjson? | .cwd) // null)
            else
                ($l.v | fromjson? // {}) as $j
                | if   $j.type == "agent-name"  then .[$l.f].name = $j.agentName
                  elif $j.type == "ai-title"    then .[$l.f].ai   = $j.aiTitle
                  elif $j.type == "last-prompt" then .[$l.f].last = $j.lastPrompt
                  else . end
            end)
        | to_entries
        | map(.value + {sid: (.key | split("/") | last | rtrimstr(".jsonl"))})
        | map(select(.cwd and (.name // .ai // .last)))
        | sort_by(-.mtime)
        | map(. + {dir: (.cwd | if startswith($home) then "~" + .[($home | length):] else . end | fit(40))})
        | (map(.dir | width) | max | [., 40] | min) as $w
        | .[]
        | [ "\(.mtime | strflocaltime("%Y-%m-%d %H:%M"))  \(.dir | pad($w))\((.name // .ai // .last) | gsub("\\s+"; " ") | .[0:120])",
            .cwd,
            .sid ]
        | @tsv'
}

pause() {
    read -rsn1 -p "$1 (아무 키나 누르면 돌아감)" </dev/tty
}

# 하나라도 살아 있으면 참
alive() {
    local p
    for p; do kill -0 "$p" 2>/dev/null && return 0; done
    return 1
}

# 세션 본문(jsonl)과 같은 세션 ID의 부가 데이터 경로를 targets에 수집
collect_targets() {
    local f
    targets=()
    for f in "$PROJECTS_DIR"/*/"$1".jsonl "$PROJECTS_DIR"/*/"$1" \
             "$CLAUDE_CONFIG_DIR/file-history/$1" "$CLAUDE_CONFIG_DIR/session-env/$1"; do
        [ -e "$f" ] && targets+=("$f")
    done
}

# 세션 데이터를 휴지통으로 이동 (실행 중이면 프로세스 종료 후)
delete_session() {
    local sid=$1 f pid start ans targets=() pids=()
    case $sid in ''|*/*|.*) return 1 ;; esac

    # 세션을 실행 중인 claude 프로세스 수집
    # pid 재사용 오판 방지로 레지스트리 시작 시각(UTC lstart)과 실제 시작 시각 비교, 불일치 시 삭제 거부
    for f in "$CLAUDE_CONFIG_DIR"/sessions/*.json; do
        [ -e "$f" ] || continue
        IFS=$'\t' read -r pid start <<<"$(jq -r --arg sid "$sid" \
            'select(.sessionId == $sid) | [.pid, .procStart // ""] | @tsv' "$f" 2>/dev/null)"
        [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null || continue
        # echo $(...) 로 공백 정규화
        if [ "$(echo $(TZ=UTC LC_ALL=C ps -o lstart= -p "$pid"))" = "$(echo $start)" ]; then
            pids+=("$pid")
        else
            pause "pid $pid 가 이 세션 프로세스인지 확인 불가 ($f), 삭제 중단"
            return 1
        fi
    done

    collect_targets "$sid"
    [ ${#targets[@]} -gt 0 ] || return 0

    echo "아래 항목을 휴지통으로 이동"
    printf '  %s\n' "${targets[@]}"
    [ ${#pids[@]} -gt 0 ] && echo "실행 중인 세션: 삭제 전 프로세스 강제 종료 (pid ${pids[*]})"
    read -r -p "정말 삭제하시겠습니까? (y/n): " ans </dev/tty
    case $ans in y|Y) ;; *) return 0 ;; esac

    if [ ${#pids[@]} -gt 0 ]; then
        # SIGTERM 후 최대 5초 대기, 남아 있으면 SIGKILL
        kill "${pids[@]}" 2>/dev/null
        for _ in 1 2 3 4 5 6 7 8 9 10; do
            alive "${pids[@]}" || break
            sleep 0.5
        done
        alive "${pids[@]}" && { kill -9 "${pids[@]}" 2>/dev/null; sleep 0.5; }
        if alive "${pids[@]}"; then
            pause "프로세스 종료 실패 (pid ${pids[*]}), 삭제 중단"
            return 1
        fi
        # 종료 과정에서 새로 생긴 부가 데이터 포함
        collect_targets "$sid"
    fi

    if command -v trash >/dev/null; then
        trash "${targets[@]}" || pause "휴지통 이동 실패"
    else
        # trash 없는 환경: 세션 파일만 삭제
        rm -f -- "$PROJECTS_DIR"/*/"$sid".jsonl
        pause "trash 명령 없음: 세션 파일만 삭제, 부가 폴더는 남김"
    fi
}

PROMPT_NORMAL='claude> '
PROMPT_ARMED='삭제하려면 Ctrl-D 한 번 더> '
self=$(printf %q "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")")

case "${1:-}" in
    --list)   list_sessions; exit ;;
    --delete) delete_session "${2:-}"; exit ;;
    # 첫 Ctrl-D는 프롬프트 경고만, 경고 상태에서 다시 누르면 삭제 확인 진행
    --ctrl-d)
        if [ "${FZF_PROMPT:-}" = "$PROMPT_ARMED" ]; then
            echo "execute($self --delete ${2:-})+reload($self --list)+change-prompt($PROMPT_NORMAL)"
        else
            echo "change-prompt($PROMPT_ARMED)"
        fi
        exit ;;
esac

# 커서 이동·검색어 변경 시 삭제 경고 해제
selected=$(list_sessions | fzf -e --layout=reverse --prompt="$PROMPT_NORMAL" \
    --delimiter=$'\t' --with-nth=1 \
    --header='모든 디렉토리 세션 (Enter: 해당 디렉토리에서 resume / Ctrl-D 두 번: 삭제)' \
    --bind "ctrl-d:transform($self --ctrl-d {3})" \
    --bind "focus:change-prompt($PROMPT_NORMAL)" \
    --bind "change:change-prompt($PROMPT_NORMAL)") || exit 0

IFS=$'\t' read -r _ cwd sid <<<"$selected"

cd "$cwd" 2>/dev/null || { echo "allclaude: 디렉토리 없음: $cwd" >&2; exit 1; }
echo "→ cd $cwd && claude --resume $sid"
exec claude --resume "$sid"
