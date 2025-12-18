#!/bin/bash
# Claude Code Status Line - Matching Powerlevel10k Pure theme

# Read JSON input from stdin
input=$(cat)

# Extract key information
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
model_name=$(echo "$input" | jq -r '.model.display_name')
output_style=$(echo "$input" | jq -r '.output_style.name')

# P10k color codes (using $'...' syntax for ANSI escape interpretation)
blue=$'\033[38;5;117m'      # #57C7FF - for directory
yellow=$'\033[38;5;228m'    # #F3F99D - for git branch
magenta=$'\033[38;5;213m'   # #FF6AC1 - for prompt char
cyan=$'\033[38;5;159m'      # #9AEDFE - for model name
grey=$'\033[38;5;242m'      # for secondary info
reset=$'\033[0m'

# Get directory basename
dir_name=$(basename "$current_dir")

# Get git branch if in repo
git_info=""
if git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    git_info=" ${yellow}${branch}${reset}"
  fi
fi

# Calculate context window usage percentage (if available)
ctx_info=""
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ]; then
  current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
  size=$(echo "$input" | jq '.context_window.context_window_size')
  pct=$((current * 100 / size))
  ctx_info=" ${grey}${pct}%${reset}"
fi

# Add output style if not default
style_info=""
if [ "$output_style" != "default" ] && [ "$output_style" != "null" ]; then
  style_info=" ${grey}[${output_style}]${reset}"
fi

# Build status line
echo "${blue}${dir_name}${reset}${git_info} ${magenta}❯${reset} ${grey}|${reset} ${cyan}${model_name}${reset}${style_info}${ctx_info}"
