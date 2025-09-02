#!/bin/bash

# Kill the current tmux session after switching to the session that was last attached before it.

# shellcheck disable=SC2155
readonly current_session="$(tmux display-message -p "#S")"
readonly previous_session="$(
  tmux list-sessions -F "#{session_last_attached} #{session_name}" |
    sort -nr |
    sed -n 2p |
    awk '{print $2}'
)"

tmux switch-client -t "$previous_session"
tmux kill-session -t "$current_session"
