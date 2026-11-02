#!/bin/bash
# Background panes: every session has a window named "bg" at index 0 that
# hosts long-running processes (proxies, dev servers...).
#
# Usage:
#   bg.sh bg <pane_id> [label]  Send a pane to its session's bg window
#   bg.sh fg <pane_id>          Bring a bg pane back to the window it came from
#   bg.sh sync                  Make sure every session has a bg window and
#                               refresh the status bar counters
#
# The bg window is never left without a pane: when it hosts no process, it
# holds a process-less placeholder pane (created with `split-window ''`).
#
# Pane options:
#   @bg_label        Name shown for the process
#   @bg_origin       Id of the window the pane was sent from
#   @bg_placeholder  Set on the placeholder pane
# Session options (read by the status bar):
#   @bg_running      Number of running bg processes
#   @bg_dead         Number of bg processes that exited

# shellcheck disable=SC2155

set -euo pipefail

readonly BG_WINDOW="bg"
readonly PLACEHOLDER_TEXT="No background processes. Use prefix + B in a pane to send it here."

# --- helpers -----------------------------------------------------------------

lock() {
  # Hooks can fire several syncs at once; serialize them so we never create
  # two bg windows in the same session.
  local lock_dir="${TMPDIR:-/tmp}/tmux-bg-$(id -u).lock"
  local tries=0
  until mkdir "$lock_dir" 2>/dev/null ; do
    tries=$((tries + 1))
    if [ "$tries" -ge 50 ] ; then # ~5s: assume a stale lock
      rm -rf "$lock_dir"
    fi
    sleep 0.1
  done
  trap 'rm -rf "'"$lock_dir"'"' EXIT
}

bg_window_id() { # <session_id>
  tmux list-windows -t "$1" -F "#{window_name} #{window_id}" |
    awk -v name="$BG_WINDOW" '$1 == name {print $2; exit}'
}

add_placeholder() { # <window_id>
  local pane_id="$(printf '%s\n' "$PLACEHOLDER_TEXT" | tmux split-window -d -I -P -F "#{pane_id}" -t "$1")"
  tmux set -p -t "$pane_id" @bg_placeholder 1
  tmux select-layout -t "$1" tiled
}

remove_placeholders() { # <window_id>
  tmux list-panes -t "$1" -F "#{@bg_placeholder} #{pane_id}" |
    awk '$1 == "1" {print $2}' |
    while read -r pane_id ; do tmux kill-pane -t "$pane_id" ; done
}

process_count() { # <window_id>
  tmux list-panes -t "$1" -F "#{@bg_placeholder}" | grep -vc '^1$' || true
}

ensure_bg_window() { # <session_id> -> prints the bg window id
  local session="$1"
  local window_id="$(bg_window_id "$session")"

  if [ -z "$window_id" ] ; then
    # Insert at index 0, shifting the other windows right if 0 is taken
    local insert=(-t "${session}:0")
    if tmux list-windows -t "$session" -F "#{window_index}" | grep -qx 0 ; then
      insert=(-b "${insert[@]}")
    fi
    window_id="$(tmux new-window -d "${insert[@]}" -n "$BG_WINDOW" -P -F "#{window_id}")"
    local shell_pane="$(tmux list-panes -t "$window_id" -F "#{pane_id}")"
    add_placeholder "$window_id"
    tmux kill-pane -t "$shell_pane"
  elif [ "$(tmux display -p -t "$window_id" "#{window_index}")" != 0 ] ; then
    # Someone moved it: put it back in front
    tmux move-window -b -s "$window_id" -t "${session}:0" 2>/dev/null || true
  fi

  echo "$window_id"
}

refresh_counters() { # <session_id>
  local session="$1"
  local window_id="$(bg_window_id "$session")"
  local running=0 dead=0
  if [ -n "$window_id" ] ; then
    read -r running dead < <(
      tmux list-panes -t "$window_id" -F "#{@bg_placeholder}:#{pane_dead}" |
        awk -F ':' '$1 != "1" { if ($2 == "1") d++; else r++ } END {print r+0, d+0}'
    )
  fi
  tmux set -t "$session" @bg_running "$running"
  tmux set -t "$session" @bg_dead "$dead"
}

sync_session() { # <session_id>
  local window_id="$(ensure_bg_window "$1")"
  local count="$(process_count "$window_id")"
  local placeholders="$(tmux list-panes -t "$window_id" -F "#{@bg_placeholder}" | grep -c '^1$' || true)"

  if [ "$count" -gt 0 ] && [ "$placeholders" -gt 0 ] ; then
    remove_placeholders "$window_id"
  elif [ "$count" -eq 0 ] && [ "$placeholders" -eq 0 ] ; then
    add_placeholder "$window_id"
  fi
  tmux select-layout -t "$window_id" tiled
  refresh_counters "$1"
}

pane_session() { # <pane_id> -> prints its session id
  tmux display -p -t "$1" "#{session_id}"
}

# --- commands ----------------------------------------------------------------

cmd_sync() {
  lock
  tmux list-sessions -F "#{session_id}" | while read -r session ; do
    sync_session "$session"
  done
}

cmd_bg() { # <pane_id> [label]
  local pane_id="$1"
  local label="${2:-}"
  lock

  local session="$(pane_session "$pane_id")"
  local window_id="$(ensure_bg_window "$session")"
  local pane_window="$(tmux display -p -t "$pane_id" "#{window_id}")"

  if [ "$pane_window" = "$window_id" ] ; then
    tmux display-message "Pane is already in the background"
    exit 0
  fi

  [ -n "$label" ] || label="$(tmux display -p -t "$pane_id" "#{pane_current_command}")"

  tmux set -p -t "$pane_id" @bg_label "$label"
  tmux set -p -t "$pane_id" @bg_origin "$pane_window"
  tmux set -p -t "$pane_id" remain-on-exit on # keep crashed processes visible

  # Make room first so the split doesn't fail with "pane too small"
  tmux select-layout -t "$window_id" tiled
  tmux join-pane -d -s "$pane_id" -t "$window_id" 2>/dev/null ||
    tmux join-pane -d -f -s "$pane_id" -t "$window_id"

  remove_placeholders "$window_id"
  tmux select-layout -t "$window_id" tiled
  refresh_counters "$session"
  tmux display-message "Sent \"$label\" to the background"
}

cmd_fg() { # <pane_id>
  local pane_id="$1"
  lock

  if [ "$(tmux display -p -t "$pane_id" "#{@bg_placeholder}")" = 1 ] ; then
    exit 0
  fi

  local session="$(pane_session "$pane_id")"
  local window_id="$(bg_window_id "$session")"
  local label="$(tmux display -p -t "$pane_id" "#{@bg_label}")"
  local origin="$(tmux display -p -t "$pane_id" "#{@bg_origin}")"

  # Keep the bg window alive if this was its last process
  if [ "$(process_count "$window_id")" -le 1 ] ; then
    add_placeholder "$window_id"
  fi

  tmux set -p -t "$pane_id" -u @bg_label
  tmux set -p -t "$pane_id" -u @bg_origin
  tmux set -p -t "$pane_id" -u remain-on-exit

  # Back to the window it came from if it still exists in this session,
  # otherwise into a new window named after the process
  local origin_session=""
  if [ -n "$origin" ] ; then
    origin_session="$(tmux display -p -t "$origin" "#{session_id}" 2>/dev/null || true)"
  fi
  if [ "$origin_session" = "$session" ] && tmux join-pane -h -s "$pane_id" -t "$origin" 2>/dev/null ; then
    tmux select-window -t "$origin"
  else
    tmux break-pane -s "$pane_id" -t "${session}:" -n "${label:-fg}"
  fi
  tmux select-pane -t "$pane_id"

  tmux select-layout -t "$window_id" tiled
  refresh_counters "$session"
}

case "${1:-}" in
  bg)   shift ; cmd_bg "$@" ;;
  fg)   shift ; cmd_fg "$@" ;;
  sync) cmd_sync ;;
  *)    echo >&2 "Usage: $(basename "$0") bg <pane_id> [label] | fg <pane_id> | sync" ; exit 1 ;;
esac
