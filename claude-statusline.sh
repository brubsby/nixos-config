#!/usr/bin/env bash
# Claude Code status line - styled after Powerlevel10k Pure theme

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# ANSI color codes (matching p10k Pure palette)
grey='\033[38;5;242m'
blue='\033[38;5;4m'
cyan='\033[38;5;6m'
yellow='\033[38;5;3m'
reset='\033[0m'

# --- Directory (blue) ---
dir_part=""
if [ -n "$cwd" ]; then
  # Shorten home directory to ~
  short_cwd="${cwd/#$HOME/\~}"
  dir_part="$(printf "${blue}%s${reset}" "$short_cwd")"
fi

# --- Git info (grey) ---
git_part=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree --no-optional-locks 2>/dev/null | grep -q true; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null | sed 's/^/@/')
  dirty=""
  if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    dirty="*"
  elif [ -n "$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null)" ]; then
    dirty="*"
  fi
  ahead_behind=""
  upstream=$(git -C "$cwd" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
  if [ -n "$upstream" ]; then
    ahead=$(git -C "$cwd" rev-list --count "$upstream"..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$cwd" rev-list --count "HEAD..$upstream" 2>/dev/null || echo 0)
    [ "$ahead" -gt 0 ] && ahead_behind="${ahead_behind}:⇡"
    [ "$behind" -gt 0 ] && ahead_behind="${ahead_behind}:⇣"
  fi
  git_part="$(printf "${grey}%s%s%s${reset}" "$branch" "$dirty" "$ahead_behind")"
fi

# --- Model (grey) ---
model_part=""
if [ -n "$model" ]; then
  model_part="$(printf "${grey}%s${reset}" "$model")"
fi

# --- Context usage (yellow if high, grey otherwise) ---
ctx_part=""
if [ -n "$used_pct" ]; then
  used_int=${used_pct%.*}
  if [ "$used_int" -ge 75 ] 2>/dev/null; then
    ctx_part="$(printf "${yellow}ctx:%s%%%s" "$used_int" "$(printf "${reset}")")"
  else
    ctx_part="$(printf "${grey}ctx:%s%%%s" "$used_int" "$(printf "${reset}")")"
  fi
fi

# --- Assemble parts with spaces ---
parts=()
[ -n "$dir_part" ]   && parts+=("$dir_part")
[ -n "$git_part" ]   && parts+=("$git_part")
[ -n "$model_part" ] && parts+=("$model_part")
[ -n "$ctx_part" ]   && parts+=("$ctx_part")

printf "%s" "$(IFS=' '; echo "${parts[*]}")"
