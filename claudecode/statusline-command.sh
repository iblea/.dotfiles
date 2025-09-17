#!/bin/bash

# Read Claude Code context from stdin
input=$(cat)

# Extract information
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
username=$(whoami)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Abbreviate home directory with ~
if [[ "$cwd" == "$HOME"* ]]; then
    cwd_display="~${cwd#$HOME}"
else
    cwd_display="$cwd"
fi

# Get git branch if in a git repo (skip locks for performance)
git_branch=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
        git_branch="$branch"
    fi
fi

# Text-only colors (no backgrounds) with powerline separators
# Using ANSI color codes that work well in dimmed terminal output
SEP=""  # Powerline separator
MODEL_FG="34"    # Blue text for model
USER_FG="32"     # Green text for user
DIR_FG="33"      # Yellow text for directory
GIT_FG="31"      # Red text for git
RESET="0"        # Reset

# Build the status line
status_line=""

# Model segment
status_line+="\033[${MODEL_FG}m  $model \033[0m"
status_line+="\033[${MODEL_FG}m$SEP\033[0m"

# User segment
status_line+="\033[${USER_FG}m  $username \033[0m"
status_line+="\033[${USER_FG}m$SEP\033[0m"

# Directory segment
status_line+="\033[${DIR_FG}m  $cwd_display \033[0m"

# Git segment (only if in a git repo)
if [[ -n "$git_branch" ]]; then
    status_line+="\033[${DIR_FG}m$SEP\033[0m"
    status_line+="\033[${GIT_FG}m  $git_branch \033[0m"
    status_line+="\033[${GIT_FG}m$SEP\033[0m"
else
    status_line+="\033[${DIR_FG}m$SEP\033[0m"
fi

# Output the status line
printf "$status_line"