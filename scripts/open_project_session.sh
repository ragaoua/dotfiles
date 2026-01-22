#!/bin/bash
# shellcheck disable=SC2155
set -euo pipefail

slugify() {
  while IFS= read -r string; do
    echo "$string" | iconv -t "ascii//TRANSLIT" 2>/dev/null | sed -r 's/[^[:alnum:]]+/-/g' | tr "[:upper:]" "[:lower:]" | sed -e 's/^-//g' -e 's/-$//g'
  done
}

project_name="${1-}"

readonly projects_dir="${HOME}/Projects"

declare project_full_path;
if [ -z "$project_name" ] ; then
  readonly search_dirs="$(fd . "$projects_dir" --type=directory --max-depth=1)"
  readonly project_full_path="$(echo "${search_dirs[@]}" | fzf --tmux)"
else
  readonly project_full_path="${projects_dir}/${project_name}"
fi

if [ -z "$project_full_path" ] || [ ! -d "$project_full_path" ] ; then
  echo >&2 "Directory \"$project_full_path\" not found"
  exit 1
fi

readonly project_name="$(basename "$project_full_path" | slugify)"

if ! tmux has-session -t "$project_name" 2>/dev/null ; then
  tmux new-session -d -s "$project_name" -c "$project_full_path" \; rename-window bash
  tmux new-window -t "$project_name" -c "$project_full_path" -n nvim "nvim ."
fi

cmd="attach-session"
if [ ! -z "$TMUX" ] ; then
  cmd="switch-client"
fi

tmux "$cmd" -t "$project_name"
