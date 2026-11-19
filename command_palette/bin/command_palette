#!/bin/bash

if [ -z "${COMMAND_PALETTE_FILE:-}" ]; then
  COMMAND_PALETTE_FILE="${XDG_CONFIG_HOME:-${HOME}/.config}/command_palette/commands.json"
fi

declare entries
declare selected

if ! command -v jq >/dev/null 2>&1 || ! command -v fzf >/dev/null 2>&1; then
  echo 'jq and fzf required' >&2
  exit 1
fi

if [ ! -r "${COMMAND_PALETTE_FILE}" ]; then
  echo "Command palette file is not readable: ${COMMAND_PALETTE_FILE}" >&2
  exit 2
fi

if ! entries="$(jq -er '
  def valid_text:
    if type != "string" then false
    else length > 0 and (test("[\\t\\r\\n]") | not)
    end;
  def valid_entry:
    if type != "object" then false
    else (.title | valid_text) and (.command | valid_text)
    end;

  if type != "array" or length == 0 then
    error("expected a non-empty array")
  elif any(.[]; valid_entry | not) then
    error("each entry needs non-empty, single-line title and command strings")
  else
    .[] | "\(.title)\t\(.command)"
  end
' "${COMMAND_PALETTE_FILE}")"; then
  echo "Invalid command palette file: ${COMMAND_PALETTE_FILE}" >&2
  exit 3
fi

selected="$(echo "${entries}" | fzf \
  --height=40% \
  --layout=reverse \
  --border \
  --delimiter=$'\t' \
  --prompt='command> ' \
  --header='Enter: insert command')"

if [ -n "${selected}" ]; then
  echo "${selected#*$'\t'}"
fi
