#!/bin/bash
# Opens or moves a tmux window to the target index, then selects it.

# shellcheck disable=SC2155

set -euo pipefail

if [ -z "${TMUX:-}" ] ; then
  echo >&2 "Not in a tmux session."
  exit 1
fi

readonly window_target_index="$1"
readonly window_name="$2"
readonly window_shell_command="${3:-}"
readonly window_initial_index="$(
  tmux list-windows -F "#{window_index} #{window_name}" |
    awk -v name="$window_name" '$2 == name {print $1}'
)"

if [ "$window_initial_index" = "$window_target_index" ] ; then
  tmux select-window -t "${window_target_index}"
  exit 0
fi

readonly last_window_index="$(
  tmux list-windows -F "#{window_index}" |
    awk 'max < $1 {max = $1} END {print max}'
  )"

if [ -z "$window_initial_index" ] ; then
  # Window doesn't exist and its index may be occupied by another one >
  # right-shift every window from the last index down to index
  # $window_target_index, then create the window at the right index
  if [ -n "$last_window_index" ] && [ "$last_window_index" -ge "$window_target_index" ] ; then
    # NOTE: '|| true' is here to stop an error from halting the script.
    # It can happen when there is a gap in the numbering of windows,
    # causing the move-window command to fail because of the absence
    # of a window in the sequence
    for index in $(seq "$last_window_index" -1 "$window_target_index") ; do
      tmux move-window -s "${index}" -t "$((index + 1))" || true
    done
  fi

  readonly path="$(tmux display-message -p '#{pane_current_path}')"
  # shellcheck disable=SC2086
  tmux new-window -t "${window_target_index}" -c "$path" -n "$window_name" "$SHELL -ic \"$window_shell_command\""
else
  if [ -n "$last_window_index" ] && [ "$last_window_index" -le "$window_target_index" ] ; then
    # Window exists and its target index isn't is use > move it there
    tmux move-window -s "$window_initial_index" -t "$window_target_index"
  else
    # Window exists but its index may be occupied by another one >
    # move it at the end, then:
    # - If it's located after its target index, right-shift every window from index
    #   $window_initial_index down to $window_target_index by one
    # - If it's located before its target index, left-shift every window from index
    #   $window_initial_index+1 up to $window_target_index by one
    # then move the window again, into its target index
    readonly window_tmp_index="$((last_window_index + 1))"
    tmux move-window -s "${window_initial_index}" -t "$window_tmp_index"

    if [ "$window_initial_index" -gt "$window_target_index" ] ; then
      for index in $(seq "$((window_initial_index - 1))" -1 "$window_target_index") ; do
        # NOTE: '|| true' is here to stop an error from halting the script.
        # It can happen when there is a gap in the numbering of windows,
        # causing the move-window command to fail because of the absence
        # of a window in the sequence
        tmux move-window -s "${index}" -t "$((index + 1))" || true
      done
    else
      for index in $(seq "$((window_initial_index + 1))" 1 "$window_target_index") ; do
        tmux move-window -s "${index}" -t "$((index - 1))"
      done
    fi

    tmux move-window -s "$window_tmp_index" -t "$window_target_index"
  fi

fi

tmux select-window -t "${window_target_index}"
