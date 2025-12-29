#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 [arguments...]"
  echo "ex: $0 CLAUDE.md"
  echo "ex: $0 GEMINI.md"
  echo "ex: $0 AGENTS.md"
  exit 1
fi

echo "This script overwrite agnets file."
echo "so backup your file first if needed."
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

overwrite_agentfile "AGENTS.md" "$1"
overwrite_agentfile "global_prompt.md"
overwrite_agentfile "external_userdefined_command.md"

echo "done."
