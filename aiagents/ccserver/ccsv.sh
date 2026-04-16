#!/usr/bin/env bash
# ccsv.sh - Claude Code Sidecar wrapper (tmux 전용)
#
# 동작:
#   1. ccserver(WebSocket MCP 서버)를 백그라운드로 실행
#   2. listen 준비되면 포트 번호를 환경변수에 주입
#   3. claude 실행 (Claude Code CLI가 IDE 통합으로 ccserver에 자동 연결)
#   4. claude 종료 시 ccserver도 함께 종료
#
# 사용:
#   tmux 세션 안에서: ./ccsv.sh [claude args...]

set -euo pipefail

# ---- 사전 조건 ----
if [[ -z "${TMUX:-}" ]]; then
  echo "[ccsv] tmux 세션 안에서만 동작해. tmux 열고 다시 실행해줘." >&2
  exit 1
fi

# ---- 경로/로그 ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CCSERVER_BIN="${CCSERVER_BIN:-$SCRIPT_DIR/src/index.js}"
READY_FILE="$(mktemp -t ccserver-ready.XXXXXX)"
if [[ "${CCSERVER_DEBUG:-0}" == "1" ]]; then
  LOG_FILE="${CCSERVER_LOG:-/tmp/ccserver-$$.log}"
else
  LOG_FILE="/dev/null"
fi
CCSERVER_PID=""

# ---- 정리 루틴 ----
cleanup() {
  if [[ -n "$CCSERVER_PID" ]] && kill -0 "$CCSERVER_PID" 2>/dev/null; then
    kill "$CCSERVER_PID" 2>/dev/null || true
    wait "$CCSERVER_PID" 2>/dev/null || true
  fi
  rm -f "$READY_FILE"
}
trap cleanup EXIT INT TERM

# ---- ccserver 바이너리 확인 ----
if [[ ! -f "$CCSERVER_BIN" ]]; then
  echo "[ccsv] ccserver가 없어: $CCSERVER_BIN" >&2
  echo "[ccsv] CCSERVER_BIN 환경변수로 경로를 지정하거나 먼저 빌드해야 해." >&2
  exit 1
fi

# ---- 1. ccserver를 백그라운드로 실행 ----
# ccserver는 listen 시작되면 --ready-file 경로에 포트 번호 한 줄 기록해야 함
if [[ "${CCSERVER_DEBUG:-0}" == "1" ]]; then
  export CCSERVER_LOG_LEVEL="${CCSERVER_LOG_LEVEL:-debug}"
fi
node "$CCSERVER_BIN" --ready-file "$READY_FILE" > "$LOG_FILE" 2>&1 &
CCSERVER_PID=$!

# ---- 2. ready 신호 대기 (최대 5초) ----
for _ in {1..50}; do
  if [[ -s "$READY_FILE" ]]; then
    break
  fi
  if ! kill -0 "$CCSERVER_PID" 2>/dev/null; then
    echo "[ccsv] ccserver 시작 실패. 로그:" >&2
    cat "$LOG_FILE" >&2
    exit 1
  fi
  sleep 0.1
done

CCWSPORT="$(cat "$READY_FILE" 2>/dev/null || true)"
if [[ -z "$CCWSPORT" ]]; then
  echo "[ccsv] ccserver가 5초 안에 준비되지 않았어." >&2
  cat "$LOG_FILE" >&2
  exit 1
fi

# ---- 3. Claude Code가 인식하는 환경변수 주입 ----
export CLAUDE_CODE_SSE_PORT="$CCWSPORT"
export ENABLE_IDE_INTEGRATION="true"
export CCWSPORT  # 디버깅/기타 도구용

if [[ "${CCSERVER_DEBUG:-0}" == "1" ]]; then
  echo "[ccsv] ccserver ready on port $CCWSPORT (pid=$CCSERVER_PID, log=$LOG_FILE)" >&2
else
  echo "[ccsv] ccserver ready on port $CCWSPORT (pid=$CCSERVER_PID)" >&2
fi
echo "[ccsv] CLAUDE_CODE_SSE_PORT=$CLAUDE_CODE_SSE_PORT" >&2

# ---- 4. claude 실행 (종료 시 trap이 ccserver 정리) ----
claude "$@"
