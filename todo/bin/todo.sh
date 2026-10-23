#!/bin/bash

# Open the to-do directory with $VISUAL, $EDITOR or vi, in the terminal or in a
# tmux popup. Each category is a directory under TODO_DIR, and each to-do a
# file in it (named e.g. after its creation time) containing the to-do text.
# Compatible with the bash 3.2 shipped with macOS.

set -euo pipefail

TODO_DIR="${TODO_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/todo}"

# Neovim startup command: expands every category in neo-tree, once the tree is
# rendered (expanding before fails).
NVIM_EXPAND_LUA='
local ok, events = pcall(require, "neo-tree.events")
if not ok then return end
local handler = { event = events.AFTER_RENDER, id = "todo_expand_all" }
handler.handler = function(state)
  events.unsubscribe(handler)
  require("neo-tree.sources.filesystem.commands").expand_all_nodes(state)
end
events.subscribe(handler)
'

usage() {
  cat <<USAGE
Usage: todo.sh [option]

Opens the to-do directory with \$VISUAL, \$EDITOR or vi.

Options:
  --popup     Open the to-do directory in a tmux popup, closed when the editor exits
  --path      Print the path of the to-do directory instead of opening it
  -h, --help  Show this help

Environment:
  TODO_DIR    To-do location (${TODO_DIR})
USAGE
}

die() {
  echo "todo: $*" >&2
  exit 1
}

count_todos() {
  [ -d "${TODO_DIR}" ] || {
    echo 0
    return
  }
  find "${TODO_DIR}" -mindepth 2 -type f ! -name '.*' | wc -l | tr -d ' '
}

open_todo() {
  local editor="${VISUAL:-${EDITOR:-vi}}"

  mkdir -p "${TODO_DIR}"
  cd "${TODO_DIR}"
  # Unquoted on purpose, the editor may come with arguments (e.g. "code -w")
  # shellcheck disable=SC2086
  case "$(basename "${editor%% *}")" in
  nvim) exec ${editor} -c "lua ${NVIM_EXPAND_LUA//$'\n'/ }" . ;;
  *) exec ${editor} . ;;
  esac
}

# Opens the to-do directory in a tmux popup, styled after the catppuccin theme
# when it's loaded.
popup() {
  local color

  [ -n "${TMUX:-}" ] || die "not in a tmux session"
  color="$(tmux show-options -gqv @thm_mauve)"
  tmux display-popup -E -w 60% -h 60% -b rounded -S "fg=${color:-default}" \
    -T " 󰄬 todo · $(count_todos) " "$(printf '%q' "$0")"
}

mode=open
case "${1:-}" in
-h | --help)
  usage
  exit 0
  ;;
--popup)
  mode=popup
  shift
  ;;
--path)
  mode=path
  shift
  ;;
"") ;;
*) die "unknown argument: $1 (see --help)" ;;
esac

[ "$#" -eq 0 ] || die "too many arguments (see --help)"

case "${mode}" in
open) open_todo ;;
popup) popup ;;
path) echo "${TODO_DIR}" ;;
esac
