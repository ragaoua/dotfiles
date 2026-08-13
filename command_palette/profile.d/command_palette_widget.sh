__command_palette() {
  local selected_command
  selected_command="$(command_palette.sh)" || return

  [[ -n "${selected_command}" ]] || return 0

  if ((BASH_VERSINFO[0] < 4)); then
    echo "${selected_command}"
  else
    READLINE_LINE="${selected_command}"
    READLINE_POINT=${#READLINE_LINE}
  fi
}

if [[ $- == *i* ]]; then
  if ((BASH_VERSINFO[0] < 4)); then
    bind -m emacs-standard '"\C-xx": "\C-e \C-u\C-y\ey\C-u`__command_palette`\e\C-e\er"'
  else
    bind -m emacs-standard -x '"\C-xx": __command_palette'
  fi
fi
