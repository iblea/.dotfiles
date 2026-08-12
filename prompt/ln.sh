#!/bin/bash

linking_name=""

if [ $# -eq 0 ]; then
  echo "Usage: $0 [arguments...]"
  echo "ex: $0 CLAUDE.md"
  echo "ex: $0 GEMINI.md"
  echo "ex: $0 AGENTS.md"
  echo ""

  echo "Auto Pwd Check..."

  current_pwd="$(pwd)"
  echo "current_pwd: $current_pwd"
  if [[ "$current_pwd" = "$HOME/.claude" ]]; then
	echo "claude detected"
	linking_name="CLAUDE.md"
  elif [[ "$current_pwd" = "$HOME/.gemini" ]]; then
	echo "gemini detected"
	linking_name="GEMINI.md"
  elif [[ "$current_pwd" = "$HOME/.codex" ]]; then
	echo "codex detected"
	linking_name="AGENTS.md"
  else
	echo "Error: No arguments provided."
	exit 1
  fi
else
  linking_name=$1
fi

echo "linking_name: $linking_name"
echo ""

if [ -z "$linking_name" ]; then
  echo "Error: No arguments provided."
  exit 1
fi

echo "This script overwrite agnets file."
echo "so backup your file first if needed."
echo "WARNING: ~/.claude/ , ~/.gemini 와 같이 에이전트 설정 경로에 위치한 상태에서 프롬프트를 실행시키십시오."
printf "continue? (y/n): "
stty -echo -icanon 2>/dev/null
answer=$(dd bs=1 count=1 2>/dev/null)
stty echo 2>/dev/null
echo
if [[ "$answer" = "Y" ]]; then
  answer="y"
fi
if [[ "$answer" != "y" ]]; then
  exit 1
fi

dotfilespath=$(dirname "$(realpath $0)")
pwd="$(pwd)"

function overwrite_agentfile() {
  local dotfiles_org="$1"
  local overwrite=""
  if [ $# -eq 1 ]; then
    overwrite="$1"
  else
    overwrite="$2"
  fi

  if [ -e "$overwrite" ]; then
    rm -f "$overwrite"
  fi
  ln -s "$dotfilespath"/"$dotfiles_org" "$overwrite"
}

overwrite_agentfile "AGENTS.md" "${linking_name}"
overwrite_agentfile "global_prompt.md"
# overwrite_agentfile "external_userdefined_command.md"

echo "done."
