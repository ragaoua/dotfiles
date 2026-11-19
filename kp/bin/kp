#!/bin/bash

# Pick an entry of a KeePassXC database with fzf and copy its password, using
# keepassxc-cli. The database password is kept gpg-encrypted in
# KEEPASS_PASSWORD_FILE, so that gpg-agent caches the unlock between runs.
# Compatible with the bash 3.2 shipped with macOS.

set -o pipefail
umask 077

KEEPASS_DB="${KEEPASS_DB:-${XDG_DATA_HOME:-${HOME}/.local/share}/kp/db.kdbx}"
KEEPASS_PASSWORD_FILE="${KEEPASS_PASSWORD_FILE:-${XDG_DATA_HOME:-${HOME}/.local/share}/kp/password.gpg}"
KEEPASS_CLIP_TIME="${KEEPASS_CLIP_TIME:-45}"

if [ -z "${GPG_TTY:-}" ] && tty -s; then
  GPG_TTY="$(tty)"
  export GPG_TTY
fi

usage() {
  cat <<USAGE
Usage: kp.sh [command] [args]

Without a command, opens an interactive fzf picker.

Commands:
  init <gpg-id>...     Store the database password (prompted, or read from stdin),
                       encrypted for the gpg key(s)
  ls                   List entries
  copy <entry>         Copy the password of an entry to the clipboard, cleared after ${KEEPASS_CLIP_TIME}s
  --popup              Open the interactive picker in a tmux popup

Environment:
  KEEPASS_DB             Database (${KEEPASS_DB})
  KEEPASS_PASSWORD_FILE  Encrypted database password (${KEEPASS_PASSWORD_FILE})
  KEEPASS_CLIP_TIME      Seconds before the clipboard is cleared (${KEEPASS_CLIP_TIME})
USAGE
}

# In a tmux popup, which closes as soon as the tool exits, report messages in
# the status line instead of the terminal
info() {
  if [ -n "${KEEPASS_POPUP:-}" ]; then
    tmux display-message -l "$*"
  else
    echo "$*" >&2
  fi
}

die() {
  info "kp: $*"
  exit 1
}

require_tools() {
  command -v keepassxc-cli >/dev/null 2>&1 || die "keepassxc-cli required"
  command -v gpg >/dev/null 2>&1 || die "gpg required"
  [ -r "${KEEPASS_DB}" ] || die "no database at ${KEEPASS_DB}"
}

# Sets PASSWORD to the decrypted database password. It is only ever handed to
# keepassxc-cli through printf (a builtin), so it never shows up in ps.
unlock() {
  [ -r "${KEEPASS_PASSWORD_FILE}" ] || die "password not stored, run: kp.sh init <gpg-id>"
  PASSWORD="$(gpg --quiet --decrypt "${KEEPASS_PASSWORD_FILE}")" ||
    die "failed to decrypt ${KEEPASS_PASSWORD_FILE}"
}

kpcli() {
  local command="$1"
  shift
  printf '%s' "${PASSWORD}" | keepassxc-cli "${command}" -q "$@"
}

# Lists entry paths, without groups, empty group markers and deleted entries
list_entries() {
  kpcli ls -R -f "${KEEPASS_DB}" |
    grep -v -e '/$' -e '\[empty\]$' -e '^Recycle Bin/'
}

# Copies stdin to the macOS clipboard, flagged as concealed so that clipboard
# managers (Maccy, Raycast, Alfred...) don't record it. See nspasteboard.org.
CONCEAL_COPY_JS='
ObjC.import("AppKit");
const data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
const value = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding);
const pb = $.NSPasteboard.generalPasteboard;
pb.clearContents;
pb.setStringForType(value, $.NSPasteboardTypeString);
pb.setStringForType($(""), "org.nspasteboard.ConcealedType");
'

clip_copy() {
  if command -v osascript >/dev/null 2>&1; then
    osascript -l JavaScript -e "${CONCEAL_COPY_JS}" >/dev/null
  elif command -v wl-copy >/dev/null 2>&1; then
    wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
  else
    die "no clipboard tool found (osascript, wl-copy or xclip)"
  fi
}

clip_paste() {
  if command -v pbpaste >/dev/null 2>&1; then
    pbpaste
  elif command -v wl-paste >/dev/null 2>&1; then
    wl-paste --no-newline
  elif command -v xclip >/dev/null 2>&1; then
    xclip -o -selection clipboard
  fi
}

cmd_init() {
  local recipients=() id

  [ $# -gt 0 ] || die "usage: kp.sh init <gpg-id>..."
  require_tools
  for id in "$@"; do
    recipients+=(--recipient "${id}")
  done

  # Prompted (hidden), or read from stdin when it isn't a tty
  if [ -t 0 ]; then
    IFS= read -rs -p "Password of ${KEEPASS_DB}: " PASSWORD
    echo >&2
  else
    IFS= read -r PASSWORD
  fi
  kpcli ls "${KEEPASS_DB}" >/dev/null 2>&1 || die "wrong password for ${KEEPASS_DB}"

  mkdir -p "$(dirname "${KEEPASS_PASSWORD_FILE}")" || exit
  printf '%s' "${PASSWORD}" |
    gpg --quiet --yes --batch --no-encrypt-to "${recipients[@]}" \
      --encrypt --output "${KEEPASS_PASSWORD_FILE}" ||
    die "failed to encrypt the password"
  info "Password of ${KEEPASS_DB} stored in ${KEEPASS_PASSWORD_FILE} for: $*"
}

cmd_ls() {
  require_tools
  unlock
  list_entries || die "failed to open ${KEEPASS_DB} (password changed? run: kp.sh init <gpg-id>)"
}

# Expects PASSWORD to be set
copy_entry() {
  local value checksum

  value="$(kpcli show -s -a Password "${KEEPASS_DB}" "$1")" || die "failed to read $1"
  [ -n "${value}" ] || die "no password in $1"
  printf '%s' "${value}" | clip_copy || die "failed to copy to clipboard"

  # Clear the clipboard later, unless something else has been copied meanwhile.
  # Ignore SIGHUP, sent when the terminal (e.g. a tmux popup) closes.
  checksum="$(printf '%s' "${value}" | cksum)"
  (
    trap '' HUP
    sleep "${KEEPASS_CLIP_TIME}"
    if [ "$(clip_paste | cksum)" = "${checksum}" ]; then
      printf '' | clip_copy
    fi
  ) </dev/null >/dev/null 2>&1 &
  disown

  info "Copied the password of $1 to clipboard, clearing in ${KEEPASS_CLIP_TIME}s"
}

cmd_copy() {
  [ $# -eq 1 ] || die "usage: kp.sh copy <entry>"
  require_tools
  unlock
  copy_entry "$1"
}

# The database password is decrypted once, before listing, and kept for the
# whole session: picking can take as long as needed.
cmd_interactive() {
  local entries name
  # A popup already has a border: take it whole
  local layout=(--height=40% --border)

  command -v fzf >/dev/null 2>&1 || die "fzf required"
  require_tools
  [ -n "${KEEPASS_POPUP:-}" ] && layout=(--height=100%)

  unlock
  entries="$(list_entries)" ||
    die "failed to open ${KEEPASS_DB} (password changed? run: kp.sh init <gpg-id>)"

  name="$(fzf \
    "${layout[@]}" \
    --layout=reverse \
    --prompt='kp> ' \
    --header='Enter: copy password' <<<"${entries}")" || return 0
  copy_entry "${name}"
}

# Opens the interactive picker in a tmux popup, closed when the picker exits,
# styled after the catppuccin theme when it's loaded.
# GPG_TTY is reset as the one inherited from tmux may belong to another pane.
popup() {
  local color

  [ -n "${TMUX:-}" ] || die "not in a tmux session"
  color="$(tmux show-options -gqv @thm_green)"
  tmux display-popup -E -w 60% -h 60% -b rounded -S "fg=${color:-default}" \
    -T " 󰌆 kp " \
    "KEEPASS_POPUP=1 GPG_TTY= $(printf '%q' "$0")"
}

command="${1:-}"
[ $# -gt 0 ] && shift

case "${command}" in
"") cmd_interactive ;;
--popup) popup ;;
init) cmd_init "$@" ;;
ls) cmd_ls ;;
copy) cmd_copy "$@" ;;
-h | --help | help) usage ;;
*)
  usage >&2
  exit 1
  ;;
esac
