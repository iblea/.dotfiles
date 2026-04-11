#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SFTP_JSON="$SCRIPT_DIR/sftp.json"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

#--- dependency check ---#
for cmd in jq rsync; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "[ERROR] '$cmd' is required but not installed."
        exit 1
    }
done
[ -f "$SFTP_JSON" ] || {
    echo "[ERROR] sftp.json not found: $SFTP_JSON"
    exit 1
}

#--- parse sftp.json ---#
HOST=$(jq -r '.host' "$SFTP_JSON")
PORT=$(jq -r '.port // 22' "$SFTP_JSON")
USERNAME=$(jq -r '.username' "$SFTP_JSON")
REMOTE_PATH=$(jq -r '.remotePath' "$SFTP_JSON")
PRIVATE_KEY=$(jq -r '.privateKeyPath // empty' "$SFTP_JSON")

#--- build ssh command ---#
SSH_OPTS=(-p "${PORT}")
[ -n "$PRIVATE_KEY" ] && SSH_OPTS+=(-i "${PRIVATE_KEY}")
SSH_CMD="ssh -p ${PORT}"
[ -n "$PRIVATE_KEY" ] && SSH_CMD="${SSH_CMD} -i \"${PRIVATE_KEY}\""

#--- built-in excludes (스크립트 내부에서 직접 추가/수정) ---#
BUILTIN_EXCLUDES=(
    '**/.git'
    'node_modules'
    '**/__pycache__'
)

#--- build exclude list: built-in + sftp.json ignore ---#
EXCLUDE_LIST=("${BUILTIN_EXCLUDES[@]}")
while IFS= read -r pattern; do
    EXCLUDE_LIST+=("$pattern")
done < <(jq -r '.ignore[]?' "$SFTP_JSON")

EXCLUDE_ARGS=()       # rsync --exclude
FSWATCH_EXCLUDES=()   # fswatch --exclude (regex)
INOTIFY_PARTS=()      # inotifywait --exclude parts

for pattern in "${EXCLUDE_LIST[@]+"${EXCLUDE_LIST[@]}"}"; do
    EXCLUDE_ARGS+=(--exclude="$pattern")

    # glob → regex: ** 제거, . → \., * → [^/]*, 앞뒤 / 제거
    regex="${pattern//\*\*/}"
    regex="${regex//./\\.}"
    regex="${regex//\*/[^\/]*}"
    regex="${regex#/}"
    regex="${regex%/}"

    FSWATCH_EXCLUDES+=(--exclude="${regex}")
    INOTIFY_PARTS+=("${regex}")
done

INOTIFY_EXCLUDE=""
if [ ${#INOTIFY_PARTS[@]} -gt 0 ]; then
    printf -v INOTIFY_EXCLUDE '%s|' "${INOTIFY_PARTS[@]}"
    INOTIFY_EXCLUDE="${INOTIFY_EXCLUDE%|}"
fi

REMOTE_DEST="${USERNAME}@${HOST}:${REMOTE_PATH}"

echo "=== rsync watch sync ==="
echo "Local:  ${PROJECT_DIR}"
echo "Remote: ${REMOTE_DEST} (port: ${PORT})"
echo "Press Ctrl+C to stop."
echo "========================"

delete_file() {
    local abs_path="$1"
    local rel_path="${abs_path#${PROJECT_DIR}/}"

    [[ "$rel_path" == "$abs_path" ]] && return 0

    local remote_file="${REMOTE_PATH}/${rel_path}"
    local ssh_output
    if ssh_output=$(ssh "${SSH_OPTS[@]}" "${USERNAME}@${HOST}" "rm -f '${remote_file}'" 2>&1); then
        echo "[$(date '+%H:%M:%S')] deleted: ${rel_path}"
    else
        echo "[$(date '+%H:%M:%S')] FAILED to delete: ${rel_path}"
        echo "  error: ${ssh_output}"
    fi
}

sync_file() {
    local abs_path="$1"
    local rel_path="${abs_path#${PROJECT_DIR}/}"

    # skip if outside project dir
    [[ "$rel_path" == "$abs_path" ]] && return 0
    # skip directories
    [ -d "$abs_path" ] && return 0
    # file deleted → remove from remote
    if [ ! -f "$abs_path" ]; then
        delete_file "$abs_path"
        return 0
    fi

    local rsync_output
    rsync_output=$(cd "${PROJECT_DIR}" && rsync -avz -R -e "${SSH_CMD}" \
        "${EXCLUDE_ARGS[@]+"${EXCLUDE_ARGS[@]}"}" \
        "./${rel_path}" "${REMOTE_DEST}/" 2>&1)
    local rc=$?
    if [ $rc -eq 0 ]; then
        echo "[$(date '+%H:%M:%S')] synced: ${rel_path}"
    else
        echo "[$(date '+%H:%M:%S')] FAILED(rc=${rc}): ${rel_path}"
        echo "  output: ${rsync_output}"
    fi
}

#--- OS detection & watch ---#
OS="$(uname -s)"
case "$OS" in
    Darwin)
        command -v fswatch >/dev/null 2>&1 || {
            echo "[ERROR] fswatch is required on macOS."
            echo "  Install: brew install fswatch"
            exit 1
        }
        fswatch -0 -r -l 0.5 \
            "${FSWATCH_EXCLUDES[@]+"${FSWATCH_EXCLUDES[@]}"}" \
            "${PROJECT_DIR}" | while IFS= read -r -d '' file; do
            sync_file "$file"
        done
        ;;
    Linux)
        command -v inotifywait >/dev/null 2>&1 || {
            echo "[ERROR] inotifywait is required on Linux."
            echo "  Install: apt install inotify-tools"
            exit 1
        }
        inotifywait -mrq \
            -e modify,create,move,delete \
            --format '%w%f' \
            ${INOTIFY_EXCLUDE:+--exclude "$INOTIFY_EXCLUDE"} \
            "${PROJECT_DIR}" | while IFS= read -r filepath; do
            sync_file "$filepath"
        done
        ;;
    *)
        echo "[ERROR] Unsupported OS: $OS"
        exit 1
        ;;
esac
