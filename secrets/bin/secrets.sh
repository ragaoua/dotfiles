#!/bin/bash

# Manage name/value secrets, each stored as a gpg-encrypted file in SECRETS_DIR.
# Compatible with the bash 3.2 shipped with macOS.

set -o pipefail
umask 077

SECRETS_DIR="${SECRETS_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/secrets}"
SECRETS_CLIP_TIME="${SECRETS_CLIP_TIME:-45}"
GPG_ID_FILE="${SECRETS_DIR}/.gpg-id"
NAME_PATTERN='^[A-Za-z0-9_@+=,.-]+(/[A-Za-z0-9_@+=,.-]+)*$'

if [ -z "${GPG_TTY:-}" ] && tty -s; then
  GPG_TTY="$(tty)"
  export GPG_TTY
fi

usage() {
  cat <<USAGE
Usage: secrets.sh [command] [args]

Without a command, opens an interactive fzf picker.

Commands:
  init <gpg-id>...     Set the gpg key(s) to encrypt with (re-encrypts existing secrets)
  add <name>           Add a secret (value prompted, or read from stdin)
  edit <name>          Replace the value of a secret (prompted, or read from stdin)
  mv <name> <new>      Rename a secret
  rm [-f] <name>       Remove a secret
  show <name>          Print the value of a secret
  copy <name>          Copy the value to the clipboard, cleared after ${SECRETS_CLIP_TIME}s
  ls                   List secret names
  search <pattern>     List secret names matching pattern (case insensitive)

Environment:
  SECRETS_DIR          Store location (${SECRETS_DIR})
  SECRETS_CLIP_TIME    Seconds before the clipboard is cleared (${SECRETS_CLIP_TIME})
USAGE
}

die() {
  echo "secrets: $*" >&2
  exit 1
}

require_store() {
  command -v gpg >/dev/null 2>&1 || die "gpg required"
  [ -r "${GPG_ID_FILE}" ] || die "store not initialized, run: secrets.sh init <gpg-id>"
}

validate_name() {
  [[ "$1" =~ ${NAME_PATTERN} ]] || die "invalid name: '$1' (allowed: A-Z a-z 0-9 _ @ + = , . - and / as separator)"
  [[ "/$1" != */.* ]] || die "invalid name: '$1' (components cannot start with '.')"
}

secret_path() {
  printf '%s/%s.gpg' "${SECRETS_DIR}" "$1"
}

require_secret() {
  validate_name "$1"
  [ -f "$(secret_path "$1")" ] || die "no such secret: $1"
}

list_names() {
  [ -d "${SECRETS_DIR}" ] || return 0
  find "${SECRETS_DIR}" -type f -name '*.gpg' |
    sed -e "s|^${SECRETS_DIR}/||" -e 's|\.gpg$||' |
    sort
}

prune_empty_dirs() {
  find "${SECRETS_DIR}" -mindepth 1 -type d -empty -delete
}

# Encrypts stdin into the given file, atomically.
encrypt_to() {
  local path="$1" tmp line
  local recipients=()

  while IFS= read -r line || [ -n "${line}" ]; do
    [ -n "${line}" ] && recipients+=(--recipient "${line}")
  done <"${GPG_ID_FILE}"
  [ "${#recipients[@]}" -gt 0 ] || die "no gpg id in ${GPG_ID_FILE}"

  mkdir -p "$(dirname "${path}")" || return
  tmp="$(mktemp "${path}.XXXXXX")" || return
  if gpg --quiet --yes --batch --no-encrypt-to "${recipients[@]}" \
    --encrypt --output "${tmp}"; then
    mv -f "${tmp}" "${path}"
  else
    rm -f "${tmp}"
    return 1
  fi
}

decrypt() {
  gpg --quiet --decrypt "$(secret_path "$1")"
}

# Sets VALUE from a hidden, confirmed prompt, or from stdin when it isn't a tty.
read_value() {
  local confirm

  if [ ! -t 0 ]; then
    VALUE="$(cat)"
  else
    IFS= read -rs -p "Value for $1: " VALUE
    echo >&2
    IFS= read -rs -p "Confirm value: " confirm
    echo >&2
    [ "${VALUE}" = "${confirm}" ] || die "values do not match"
  fi
  [ -n "${VALUE}" ] || die "empty value"
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
    die "no clipboard tool found (pbcopy, wl-copy or xclip)"
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
  local name

  [ $# -gt 0 ] || die "usage: secrets.sh init <gpg-id>..."
  command -v gpg >/dev/null 2>&1 || die "gpg required"
  mkdir -p "${SECRETS_DIR}" || exit
  chmod 700 "${SECRETS_DIR}"
  printf '%s\n' "$@" >"${GPG_ID_FILE}"

  list_names | while IFS= read -r name; do
    decrypt "${name}" </dev/null | encrypt_to "$(secret_path "${name}")" ||
      die "failed to re-encrypt ${name}"
    echo "Re-encrypted ${name}" >&2
  done || exit
  echo "Store initialized in ${SECRETS_DIR} for: $*" >&2
}

cmd_add() {
  [ $# -eq 1 ] || die "usage: secrets.sh add <name>"
  require_store
  validate_name "$1"
  [ ! -e "$(secret_path "$1")" ] || die "secret already exists: $1 (use edit)"
  read_value "$1"
  printf '%s' "${VALUE}" | encrypt_to "$(secret_path "$1")" || die "failed to encrypt $1"
  echo "Added $1" >&2
}

cmd_edit() {
  [ $# -eq 1 ] || die "usage: secrets.sh edit <name>"
  require_store
  require_secret "$1"
  read_value "$1"
  printf '%s' "${VALUE}" | encrypt_to "$(secret_path "$1")" || die "failed to encrypt $1"
  echo "Updated $1" >&2
}

cmd_mv() {
  [ $# -eq 2 ] || die "usage: secrets.sh mv <name> <new-name>"
  require_store
  require_secret "$1"
  validate_name "$2"
  [ ! -e "$(secret_path "$2")" ] || die "secret already exists: $2"
  mkdir -p "$(dirname "$(secret_path "$2")")" || exit
  mv "$(secret_path "$1")" "$(secret_path "$2")" || exit
  prune_empty_dirs
  echo "Renamed $1 to $2" >&2
}

cmd_rm() {
  local force=0 answer

  if [ "${1:-}" = "-f" ]; then
    force=1
    shift
  fi
  [ $# -eq 1 ] || die "usage: secrets.sh rm [-f] <name>"
  require_secret "$1"
  if [ "${force}" -eq 0 ] && [ -t 0 ]; then
    read -r -p "Remove $1? [y/N] " answer
    [[ "${answer}" == [yY]* ]] || return 0
  fi
  rm -f "$(secret_path "$1")" || exit
  prune_empty_dirs
  echo "Removed $1" >&2
}

cmd_show() {
  [ $# -eq 1 ] || die "usage: secrets.sh show <name>"
  require_store
  require_secret "$1"
  decrypt "$1"
}

cmd_copy() {
  local value checksum

  [ $# -eq 1 ] || die "usage: secrets.sh copy <name>"
  require_store
  require_secret "$1"
  value="$(decrypt "$1")" || die "failed to decrypt $1"
  printf '%s' "${value}" | clip_copy || die "failed to copy to clipboard"

  # Clear the clipboard later, unless something else has been copied meanwhile
  checksum="$(printf '%s' "${value}" | cksum)"
  (
    sleep "${SECRETS_CLIP_TIME}"
    if [ "$(clip_paste | cksum)" = "${checksum}" ]; then
      printf '' | clip_copy
    fi
  ) </dev/null >/dev/null 2>&1 &
  disown

  echo "Copied $1 to clipboard, clearing in ${SECRETS_CLIP_TIME}s" >&2
}

cmd_search() {
  [ $# -eq 1 ] || die "usage: secrets.sh search <pattern>"
  list_names | grep -iF -- "$1"
}

prompt_name() {
  local name
  read -r -p "$1" name </dev/tty
  printf '%s' "${name}"
}

cmd_interactive() {
  local out query key name new_name

  command -v fzf >/dev/null 2>&1 || die "fzf required"
  require_store

  while true; do
    out="$(list_names | fzf \
      --height=40% \
      --layout=reverse \
      --border \
      --prompt='secret> ' \
      --print-query \
      --expect=ctrl-a,ctrl-e,ctrl-d,ctrl-r \
      --header='Enter: copy | C-a: add (query as name) | C-e: edit | C-d: delete | C-r: rename')"
    # 0: selection, 1: no match (still useful to add), 130: aborted
    case $? in
    0 | 1) ;;
    *) return 0 ;;
    esac

    query="$(sed -n 1p <<<"${out}")"
    key="$(sed -n 2p <<<"${out}")"
    name="$(sed -n 3p <<<"${out}")"

    case "${key}" in
    "")
      [ -n "${name}" ] || continue
      cmd_copy "${name}"
      return
      ;;
    ctrl-a)
      new_name="${query}"
      [ -n "${new_name}" ] || new_name="$(prompt_name 'Name: ')"
      [ -n "${new_name}" ] && (cmd_add "${new_name}")
      ;;
    ctrl-e)
      [ -n "${name}" ] && (cmd_edit "${name}")
      ;;
    ctrl-d)
      [ -n "${name}" ] && (cmd_rm "${name}")
      ;;
    ctrl-r)
      [ -n "${name}" ] || continue
      new_name="$(prompt_name "Rename ${name} to: ")"
      [ -n "${new_name}" ] && (cmd_mv "${name}" "${new_name}")
      ;;
    esac
  done
}

command="${1:-}"
[ $# -gt 0 ] && shift

case "${command}" in
"") cmd_interactive ;;
init) cmd_init "$@" ;;
add) cmd_add "$@" ;;
edit) cmd_edit "$@" ;;
mv) cmd_mv "$@" ;;
rm) cmd_rm "$@" ;;
show) cmd_show "$@" ;;
copy) cmd_copy "$@" ;;
ls) list_names ;;
search) cmd_search "$@" ;;
-h | --help | help) usage ;;
*)
  usage >&2
  exit 1
  ;;
esac
