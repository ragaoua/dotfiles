#!/bin/bash
# shellcheck disable=SC2155

slugify() {
  while IFS= read -r string; do
    echo "$string" | iconv -t "ascii//TRANSLIT" 2>/dev/null | sed -r 's/[^[:alnum:]]+/-/g' | tr "[:upper:]" "[:lower:]" | sed -e 's/^-//g' -e 's/-$//g'
  done
}

readonly search_dirs="$(fd . "${HOME}/Projects" --type=directory --max-depth=1)"
readonly project_full_path="$(echo "${search_dirs[@]}" | fzf --tmux)"

if [ -z "$project_full_path" ] ; then
  exit
fi

readonly project_name="$(basename "$project_full_path" | slugify)"

if ! tmux has-session -t "$project_name" 2>/dev/null ; then
  tmux new-session -d -s "$project_name" -c "$project_full_path"
fi

cmd="attach-session"
if [ ! -z "$TMUX" ] ; then
  cmd="switch-client"
fi

tmux "$cmd" -t "$project_name"
