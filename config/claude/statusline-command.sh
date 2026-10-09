#!/bin/bash
# Claude Code Status Line - p10k lean style
# Mirrors your Powerlevel10k configuration: dir + vcs + context info

input=$(cat)

# Extract values from JSON input
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir')
model_name=$(echo "$input" | jq -r '.model.display_name')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Shorten the directory path (like p10k does)
# Show ~ for home, and truncate to last 2-3 components
home_dir="$HOME"
if [[ "$cwd" == "$home_dir" ]]; then
  dir_display="~"
elif [[ "$cwd" == "$home_dir"/* ]]; then
  dir_display="~${cwd#$home_dir}"
else
  dir_display="$cwd"
fi

# Truncate to last 2 path components if too long
if [[ $(echo "$dir_display" | tr '/' '\n' | wc -l) -gt 3 ]]; then
  dir_display="...$(echo "$dir_display" | rev | cut -d'/' -f1-2 | rev)"
fi

# Git info (similar to p10k vcs segment)
git_info=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  
  # Check for changes (like p10k shows)
  if [[ -n $(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null) ]]; then
    git_info=" $branch*"
  else
    git_info=" $branch"
  fi
fi

# Build the status line
# Format: dir git_branch | model | context%
output="$dir_display$git_info"

# Add model (short form)
short_model=$(echo "$model_name" | sed 's/Claude //' | sed 's/ Sonnet/S/' | sed 's/ Opus/O/' | sed 's/ Haiku/H/')
output="$output | $short_model"

# Add context remaining if available
if [[ -n "$remaining" ]]; then
  output="$output | ${remaining}%"
fi

echo "$output"
