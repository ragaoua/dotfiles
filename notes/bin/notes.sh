#!/bin/bash

# Open the note of the project containing a directory, in the terminal or in a
# tmux popup. Each project (a directory directly under PROJECTS_DIR) has a
# single note, stored as NOTES_DIR/<project>.md.
# Compatible with the bash 3.2 shipped with macOS.

set -euo pipefail

NOTES_DIR="${NOTES_DIR:-${HOME}/.notes}"
PROJECTS_DIR="${PROJECTS_DIR:-${HOME}/Projects}"

usage() {
  cat <<USAGE
Usage: notes.sh [option] [dir]

Opens the note of the project containing dir (default: current directory)
with \$VISUAL, \$EDITOR or vi.

Options:
  --popup     Open the note in a tmux popup, closed when the editor exits
  --path      Print the path of the note instead of opening it
  -h, --help  Show this help

Environment:
  NOTES_DIR      Notes location (${NOTES_DIR})
  PROJECTS_DIR   Projects location (${PROJECTS_DIR})
USAGE
}

die() {
  echo "notes: $*" >&2
  exit 1
}

# Prints the name of the project containing the given directory, i.e. its
# first path component under PROJECTS_DIR.
project_of() {
  local dir projects rel

  dir="$(cd "$1" 2>/dev/null && pwd -P)" || die "no such directory: $1"
  projects="$(cd "${PROJECTS_DIR}" 2>/dev/null && pwd -P)" || die "no such directory: ${PROJECTS_DIR}"

  case "${dir}/" in
  "${projects}"/?*/)
    rel="${dir#"${projects}"/}"
    echo "${rel%%/*}"
    ;;
  *) die "not in a project under ${PROJECTS_DIR}: $1" ;;
  esac
}

note_path() {
  local project

  project="$(project_of "$1")" || exit 1
  printf '%s/%s.md' "${NOTES_DIR}" "${project}"
}

open_note() {
  local project note

  project="$(project_of "$1")" || exit 1
  note="$(note_path "$1")" || exit 1
  mkdir -p "${NOTES_DIR}"
  [ -e "${note}" ] || printf '# %s\n\n\n' "${PROJECTS_DIR}/${project}" >"${note}"
  cd "${NOTES_DIR}"
  # Unquoted on purpose, the editor may come with arguments (e.g. "code -w")
  # shellcheck disable=SC2086
  exec ${VISUAL:-${EDITOR:-vi}} "${note}"
}

popup() {
  local dir="$1" project

  [ -n "${TMUX:-}" ] || die "not in a tmux session"

  # Typically run from a keybind, where stderr would land in the pane: report
  # errors as a tmux message instead
  if ! project="$(project_of "${dir}" 2>&1)"; then
    tmux display-message "${project}"
    exit 1
  fi

  tmux display-popup -E -w 80% -h 80% -d "${dir}" -T " ${project} notes " \
    "$(printf '%q ' "$0" "${dir}")"
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
-*) die "unknown option: $1 (see --help)" ;;
esac

[ "$#" -le 1 ] || die "too many arguments (see --help)"
dir="${1:-${PWD}}"

case "${mode}" in
open) open_note "${dir}" ;;
popup) popup "${dir}" ;;
path) note_path "${dir}" && echo ;;
esac
