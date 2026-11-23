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

selected=$(list_sessions | fzf -e --layout=reverse --prompt='claude> ' \
    --delimiter=$'\t' --with-nth=1 \
    --header='모든 디렉토리 세션 (Enter: 해당 디렉토리에서 resume)') || exit 0

IFS=$'\t' read -r _ cwd sid <<<"$selected"

cd "$cwd" 2>/dev/null || { echo "allclaude: 디렉토리 없음: $cwd" >&2; exit 1; }
echo "→ cd $cwd && claude --resume $sid"
exec claude --resume "$sid"
