#!/bin/bash

# shellcheck disable=SC2155
readonly search_dirs="$(fd . "${HOME}/Projects" --type=directory --max-depth=1)"
readonly project_full_path="$(echo "${search_dirs[@]}" | fzf --tmux)"

if [ -z "$project_full_path" ] ; then
  exit
fi

readonly project_name="$(basename "$project_full_path")"

if ! tmux has-session -t "$project_name" 2>/dev/null ; then
  tmux new-session -d -s "$project_name" -c "$project_full_path"
fi

cmd="attach-session"
if [ ! -z "$TMUX" ] ; then
  cmd="switch-client"
fi

tmux "$cmd" -t "$project_name"
