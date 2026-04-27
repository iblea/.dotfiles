#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(cd "${SCRIPT_DIR}/../skills" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}"

INCLUDE_HIDDEN=0
KEEP_OLD=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Zip each real (non-symlink, non-".ln") skill directory under:
  ${SKILLS_DIR}
into a separate <name>.zip file inside:
  ${OUTPUT_DIR}

Symlinked files inside skill directories are dereferenced
(stored as their real content) — this is zip(1)'s default behavior.

Options:
  -a, --all      Also include hidden directories (".system" etc.)
  -k, --keep     Keep existing zip files (default: overwrite)
  -h, --help     Show this help
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -a|--all)    INCLUDE_HIDDEN=1; shift ;;
        -k|--keep)   KEEP_OLD=1; shift ;;
        -h|--help)   usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    esac
done

if ! command -v zip >/dev/null 2>&1; then
    echo "Error: 'zip' command not found." >&2
    exit 1
fi

echo "Source : ${SKILLS_DIR}"
echo "Output : ${OUTPUT_DIR}"
echo

cd "${SKILLS_DIR}"

zipped=0
skipped=0

shopt -s nullglob
[ "${INCLUDE_HIDDEN}" -eq 1 ] && shopt -s dotglob

for entry in */; do
    name="${entry%/}"

    if [ -L "${name}" ]; then
        echo "[skip] ${name} (symlink dir)"
        skipped=$((skipped + 1))
        continue
    fi

    if [[ "${name}" == *.ln ]]; then
        echo "[skip] ${name} (.ln)"
        skipped=$((skipped + 1))
        continue
    fi

    output="${OUTPUT_DIR}/${name}.zip"

    if [ -e "${output}" ] && [ "${KEEP_OLD}" -eq 1 ]; then
        echo "[keep] ${name}.zip already exists"
        skipped=$((skipped + 1))
        continue
    fi

    rm -f "${output}"

    # zip(1) default: follows symlinks and stores the real file content.
    # -r recursive, -q quiet, -X strip extra OS metadata, -o set mtime to newest.
    if zip -r -q -X -o "${output}" "${name}"; then
        size=$(wc -c < "${output}" | tr -d ' ')
        echo "[ok ] ${name}.zip (${size} bytes)"
        zipped=$((zipped + 1))
    else
        echo "[FAIL] ${name}" >&2
        rm -f "${output}"
    fi
done

echo
echo "Done. zipped=${zipped} skipped=${skipped}"
