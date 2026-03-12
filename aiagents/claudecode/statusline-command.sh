#!/bin/bash

# Read Claude Code context from stdin
input=$(cat)
# echo "$input" > /tmp/output.json

# Extract information
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
# username=$(whoami)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')

# Calculate usage percentage based on transcript file
calculate_usage() {
    # if [ -z "$(command -v ccusage)" ]; then
    #     echo "0"
    #     return
    # fi
    max_token_plan="max"
    usage_percent=$(ccusage blocks --active --token-limit "$max_token_plan" | grep "Current Usage:" | tail -n 1 | sed -n 's/.*(\([0-9]*\).[0-9]*%).*/\1/p')
    # 10.5%
    # ccusage blocks --active --token-limit "$max_token_plan" | grep "Current Usage:" | tail -n 1 | sed -n 's/.*(\([0-9.]*\)%).*/\1/p'
    # 10% Truncate decimal points
    # ccusage blocks --active --token-limit "$max_token_plan" | grep "Current Usage:" | tail -n 1 | sed -n 's/.*(\([0-9]*\).[0-9]*%).*/\1/p'
    echo "$usage_percent"
}

# Get Claude Code process memory usage in MB
# Works on both Darwin (macOS) and Linux (Ubuntu/Debian)
# Traces parent process chain to find the node (Claude Code) process,
# then sums RSS of it and all descendant processes.
get_claude_memory() {
    local pid=$$
    local claude_pid=""

    # Traverse parent process chain to find node (Claude Code) process
    while [ "$pid" -gt 1 ] 2>/dev/null; do
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
        [ -z "$pid" ] && break
        [ "$pid" -le 1 ] && break

        local cmd
        cmd=$(ps -o comm= -p "$pid" 2>/dev/null)
        if [[ "$cmd" == *"node"* ]] || [[ "$cmd" == *"claude"* ]]; then
            claude_pid="$pid"
            # Don't break; keep going up to find the topmost node process
            # (Claude Code may spawn child node processes)
        fi
    done

    if [ -z "$claude_pid" ]; then
        echo ""
        return
    fi

    # Collect all descendant PIDs using BFS
    local all_pids="$claude_pid"
    local queue="$claude_pid"
    while [ -n "$queue" ]; do
        local next_queue=""
        for p in $queue; do
            local children
            children=$(pgrep -P "$p" 2>/dev/null)
            if [ -n "$children" ]; then
                all_pids="$all_pids $children"
                next_queue="$next_queue $children"
            fi
        done
        queue=$(echo "$next_queue" | xargs)
    done

    # Sum RSS of all processes (in KB)
    local total_rss=0
    for p in $all_pids; do
        local rss
        rss=$(ps -o rss= -p "$p" 2>/dev/null | tr -d ' ')
        if [ -n "$rss" ] && [ "$rss" -gt 0 ] 2>/dev/null; then
            total_rss=$((total_rss + rss))
        fi
    done

    # KB -> MB
    local mb=$((total_rss / 1024))
    echo "${claude_pid}:${mb}"
}

# Get memory color based on MB usage
get_memory_color() {
    local mb=$1
    if [ "$mb" -lt 500 ] 2>/dev/null; then
        echo "32"  # Green - normal
    elif [ "$mb" -lt 1000 ] 2>/dev/null; then
        echo "33"  # Yellow - moderate
    elif [ "$mb" -lt 2000 ] 2>/dev/null; then
        echo "35"  # Magenta - high
    else
        echo "31"  # Red - very high (possible leak)
    fi
}

# Generate progress bar
generate_progress_bar() {
    local percentage=$1
    local bar_length=10
    local filled_length=$(( (percentage * bar_length) / 100 ))
    local empty_length=$(( bar_length - filled_length ))

    local bar=""
    for ((i=0; i<filled_length; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty_length; i++)); do
        bar+="░"
    done

    echo "[$bar] ${percentage}%"
}

# Get usage color based on percentage
get_usage_color() {
    local percentage=$1
    if [[ $percentage -lt 50 ]]; then
        echo "32"  # Green
    elif [[ $percentage -lt 80 ]]; then
        echo "33"  # Yellow
    else
        echo "31"  # Red
    fi
}

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
# status_line+="\033[${USER_FG}m  $username \033[0m"
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

# Memory usage segment
mem_info=$(get_claude_memory)
if [ -n "$mem_info" ]; then
    claude_pid="${mem_info%%:*}"
    mem_mb="${mem_info##*:}"
    if [ -n "$mem_mb" ] && [ "$mem_mb" != "0" ]; then
        mem_color=$(get_memory_color "$mem_mb")
        status_line+="\033[${mem_color}m ${claude_pid} / ${mem_mb}MB \033[0m"
    fi
fi

if [ -n "$(command -v date)" ]; then
    # Time segment
    usage_display=$(date "+%Y-%m-%d %H:%M:%S")
    usage_color=$(get_usage_color "$usage_percentage")
    status_line+="\033[${usage_color}m  $usage_display \033[0m"
fi

# if [ -n "$(command -v ccusage)" ]; then
#     # Calculate usage
#     usage_percentage=$(calculate_usage "$transcript_path")
#     usage_display=$(generate_progress_bar "$usage_percentage")
#     usage_color=$(get_usage_color "$usage_percentage")
# 
#     # Usage segment
#     status_line+="\033[${usage_color}m  $usage_display \033[0m"
# fi

# Output the status line
echo -e "$status_line"
