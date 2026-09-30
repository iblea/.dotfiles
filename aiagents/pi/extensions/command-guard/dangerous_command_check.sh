#!/bin/bash
# dangerous_command_check.sh

if ! command -v jq >/dev/null 2>&1; then
  echo 'BLOCKED: jq is required to inspect shell commands.' >&2
  exit 2
fi

INPUT=$(cat)
if ! COMMAND=$(printf '%s' "$INPUT" | jq -er '.tool_input.command | if type == "string" then . else error("missing shell command") end'); then
  echo 'BLOCKED: the hook could not read the shell command.' >&2
  exit 2
fi

# 보수적인 토큰 검사: 셸 구문 전체의 실행 의미 분석은 제외
/usr/bin/python3 - "$COMMAND" <<'PY'
import posixpath
import sys

SEPARATORS = frozenset(";&|()`\n")
SHELLS = {"sh", "bash", "zsh", "dash", "ksh"}


def tokenize(command):
    # 따옴표 안의 ';', '|', 줄바꿈을 명령 구분자로 오인하지 않도록 구분
    tokens, word = [], []
    quote = None
    started = False
    index = 0

    def flush():
        if started:
            tokens.append(("".join(word), False))
            word.clear()

    while index < len(command):
        char = command[index]
        if quote == "'":
            if char == quote:
                quote = None
            else:
                word.append(char)
        elif quote == '"':
            if char == quote:
                quote = None
            elif char == "\\" and index + 1 < len(command) and command[index + 1] in '$`"\\\n':
                index += 1
                if command[index] != "\n":
                    word.append(command[index])
            else:
                word.append(char)
        elif char in "'\"":
            quote, started = char, True
        elif char == "\\":
            index += 1
            if index == len(command):
                raise ValueError("incomplete escape")
            if command[index] != "\n":
                word.append(command[index])
                started = True
        elif char in " \t\r" or char in SEPARATORS:
            flush()
            started = False
            if char in SEPARATORS:
                tokens.append((char, True))
        elif char == "#" and not started:
            while index < len(command) and command[index] != "\n":
                index += 1
            continue
        else:
            word.append(char)
            started = True
        index += 1
    if quote:
        raise ValueError("unclosed quote")
    flush()
    return tokens


def recursive_removal(arguments):
    for arg, is_separator in arguments:
        if arg == "--" or is_separator:
            break
        if arg.startswith("--"):
            # GNU rm의 긴 옵션 축약형 포함
            if "--recursive".startswith(arg):
                return True
        elif arg.startswith("-"):
            if any(flag in arg[1:] for flag in "rR"):
                return True
    return False


def inspect(command, depth=0):
    if depth > 8:
        raise ValueError("shell nesting exceeds the inspection limit")
    tokens = tokenize(command)

    for index, (token, is_separator) in enumerate(tokens):
        if is_separator:
            continue
        executable = posixpath.basename(token)
        # 절대 경로, sudo/env/command/xargs 뒤의 rm, GNU grm 포함
        if executable in {"rm", "grm"}:
            if recursive_removal(tokens[index + 1:]):
                return True
        # bash -c / zsh -lc 등에 전달한 정적인 명령 문자열 검사
        if executable in SHELLS:
            for offset in range(index + 1, len(tokens)):
                arg, is_separator = tokens[offset]
                if is_separator or arg == "--":
                    break
                if arg.startswith("-") and not arg.startswith("--") and "c" in arg[1:]:
                    if offset + 1 < len(tokens) and inspect(tokens[offset + 1][0], depth + 1):
                        return True
                    break
        # 따옴표 안에 포함된 정적인 명령 치환도 보수적으로 검사
        if ("$(" in token or "`" in token) and inspect(token, depth + 1):
            return True
    return False


try:
    blocked = inspect(sys.argv[1])
except ValueError:
    print("BLOCKED: the hook could not safely parse the shell command.", file=sys.stderr)
    sys.exit(2)

if blocked:
    print("BLOCKED: recursive deletion with rm/grm (-r/-R/--recursive) is not allowed. File and empty-directory deletion are allowed.", file=sys.stderr)
    sys.exit(2)
PY

rm_check_status=$?
if [ "$rm_check_status" -ne 0 ]; then
  if [ "$rm_check_status" -ne 2 ]; then
    echo 'BLOCKED: the rm command check failed.' >&2
  fi
  exit 2
fi

# Block curl piped to shell execution (curl | bash, curl | sh, etc.)
if printf '%s\n' "$COMMAND" | grep -qE 'curl\s.*\|'; then
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
if printf '%s\n' "$COMMAND" | grep -qE 'find\s.*-exec'; then
  cat >&2 <<'MSG'
BLOCKED: find with -exec can execute arbitrary commands.
Use find without -exec and handle results separately:
  find /path -name "*.sh"
MSG
  exit 2
fi

exit 0
