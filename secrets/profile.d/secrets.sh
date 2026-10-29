alias secrets='secrets.sh'

__secrets() {
  local saved_stty

  # Readline leaves the terminal in raw mode (no echo, Enter sends \r) while
  # running bind -x widgets, which breaks the tool's prompts. Restore a cooked
  # mode for the tool, then hand the terminal back to readline as it was.
  saved_stty="$(stty -g </dev/tty)"
  stty icrnl icanon echo </dev/tty
  GPG_TTY="$(tty)" secrets.sh </dev/tty
  stty "${saved_stty}" </dev/tty
}

if [[ $- == *i* ]]; then
  bind -m emacs-standard -x '"\C-xs": __secrets'
fi
