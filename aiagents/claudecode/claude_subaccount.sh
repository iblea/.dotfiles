#!/usr/bin/env bash
# Claude Code 서브 계정용 CLAUDE_CONFIG_DIR 생성 및 ~/.claude 와 세션/히스토리 공유 링크 설정
# 사용법: ~/claude_subaccount.sh "~/.claude-work"
set -euo pipefail

SRC="$HOME/.claude"
# 세션/히스토리 데이터 (기존 실데이터는 ~/.claude 로 병합 후 링크)
SESSION_ITEMS=(projects history.jsonl file-history tasks session-env paste-cache)

[ $# -eq 1 ] || { echo "사용법: $0 <서브 계정 디렉토리>  (예: $0 \"~/.claude-work\")" >&2; exit 1; }

# 따옴표로 넘어온 ~ 직접 확장
case "$1" in
  "~/"*) DST="$HOME/${1:2}" ;;
  *) DST="$1" ;;
esac
DST="${DST%/}"
BK="$DST/.link-backup-$(date +%Y%m%d-%H%M%S)"

[ -d "$SRC" ] || { echo "$SRC 없음, 중단" >&2; exit 1; }
if [ -e "$DST" ] && [ ! -d "$DST" ]; then
  echo "$DST 가 디렉토리가 아님, 중단" >&2; exit 1
fi
if [ -d "$DST" ]; then
  echo "기존 디렉토리 사용: $DST"
else
  mkdir -p "$DST"
  echo "디렉토리 생성: $DST"
fi
[ "$(cd -P "$DST" && pwd)" != "$(cd -P "$SRC" && pwd)" ] || { echo "$DST 가 $SRC 와 동일, 중단" >&2; exit 1; }

# DST 를 사용하는 실행 중 세션 확인 (데이터 이동 전)
assert_no_running_session() {
  local f pid
  for f in "$DST"/sessions/*.json; do
    [ -e "$f" ] || continue
    pid="${f##*/}"; pid="${pid%%.*}"
    if kill -0 "$pid" 2>/dev/null; then
      echo "$DST 를 사용하는 claude 세션 실행 중 (pid $pid), 종료 후 재실행 필요" >&2
      exit 1
    fi
  done
}

# 기존 실데이터를 백업 디렉토리로 이동
stash() {
  mkdir -p "$BK"
  mv "$DST/$1" "$BK/"
}

# history.jsonl 병합 (중복 줄 제거 후 timestamp 기준 정렬)
merge_history() {
  python3 -I - "$SRC/history.jsonl" "$DST/history.jsonl" <<'PY'
import json, os, sys
target, other = sys.argv[1], sys.argv[2]
seen, rows = set(), []
for path in (target, other):
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if line and line not in seen:
                seen.add(line)
                rows.append((json.loads(line).get("timestamp", 0), line))
rows.sort(key=lambda r: r[0])
tmp = target + ".merged"
with open(tmp, "w", encoding="utf-8") as f:
    f.writelines(line + "\n" for _, line in rows)
os.chmod(tmp, 0o600)
os.replace(tmp, target)
PY
}

# $1: 항목 이름, $2: 실데이터 처리 방식 (merge: ~/.claude 로 병합 / backup: 백업만)
link_item() {
  local name="$1" mode="$2" path="$DST/$1" target="$SRC/$1" cur
  if [ -L "$path" ]; then
    cur="$(readlink "$path")"
    # ~/.claude/<항목> 또는 ~/.claude 쪽 링크와 같은 대상이면 유지
    if [ "$cur" = "$target" ] || [ "$cur" = "$(readlink "$target" 2>/dev/null || true)" ]; then
      echo "  [skip]   $name (이미 링크됨)"
      return
    fi
    unlink "$path"
    echo "  [relink] $name (기존 링크: $cur)"
  elif [ -e "$path" ]; then
    assert_no_running_session
    if [ "$mode" = merge ]; then
      if [ "$name" = history.jsonl ]; then
        merge_history
      else
        rsync -a --ignore-existing --omit-dir-times "$path/" "$target/"
      fi
      echo "  [merge]  $name (기존 데이터 $SRC 로 병합)"
    else
      echo "  [backup] $name (기존 파일 백업)"
    fi
    stash "$name"
  fi
  ln -s "$target" "$path"
  echo "  [link]   $name -> $target"
}

echo "== 세션/히스토리"
for name in "${SESSION_ITEMS[@]}"; do
  if [ ! -e "$SRC/$name" ]; then
    case "$name" in
      *.jsonl) touch "$SRC/$name"; chmod 600 "$SRC/$name" ;;
      *) mkdir -p "$SRC/$name" ;;
    esac
  fi
  link_item "$name" merge
done

echo "== 공유 설정 ($SRC 의 심링크)"
for src_path in "$SRC"/*; do
  [ -L "$src_path" ] || continue
  link_item "${src_path##*/}" backup
done

echo
echo "완료: $DST"
[ ! -d "$BK" ] || echo "기존 데이터 백업: $BK"
echo "※ $DST/settings.json 은 링크 대상 아님. 따로 생성/세팅 필요"
