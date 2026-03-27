#!/bin/bash
# dangerous_command_check.sh

if [ -z "$(command -v jq)" ]; then
    # echo "This script only support Darwin."
    exit 0
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block curl piped to shell execution (curl | bash, curl | sh, etc.)
if echo "$COMMAND" | grep -qE 'curl\s.*\|'; then
  cat >&2 <<'MSG'
BLOCKED: curl with pipe is dangerous (e.g. curl | bash, curl | sh).
Instead, download the script first and verify before executing:
  curl -s "URL" > /tmp/curlscript.sh
  cat /tmp/curlscript.sh
  chmod 755 /tmp/curlscript.sh
  /tmp/curlscript.sh
MSG
  exit 2
fi

# Block find with -exec (arbitrary command execution)
if echo "$COMMAND" | grep -qE 'find\s.*-exec'; then
  cat >&2 <<'MSG'
BLOCKED: find with -exec can execute arbitrary commands.
Use find without -exec and handle results separately:
  find /path -name "*.sh"
MSG
  exit 2
fi

exit 0
