_envx() {
  local cur="${COMP_WORDS[COMP_CWORD]}" i word
  local args=()

  # Positional arguments before the cursor, flags left out
  for ((i = 1; i < COMP_CWORD; i++)); do
    word="${COMP_WORDS[i]}"
    if [ "${word}" = "--" ]; then
      # After "envx run <ns> --": complete as if the command line started
      # there, with the command's own completion (as for sudo), when
      # bash-completion is loaded. Otherwise, complete the command name, then
      # fall back to file completion (-o default).
      if declare -F _command_offset >/dev/null; then
        _command_offset $((i + 1))
      elif [ $((i + 1)) -eq "${COMP_CWORD}" ]; then
        COMPREPLY=($(compgen -c -- "${cur}"))
      fi
      return 0
    fi
    [[ "${word}" == -* ]] || args+=("${word}")
  done

  case "${#args[@]}" in
  0)
    COMPREPLY=($(compgen -W "init ls get set rm protect unprotect run shell export help" -- "${cur}"))
    ;;
  1)
    case "${args[0]}" in
    init | help) ;;
    set) COMPREPLY=($(compgen -W "-p $(envx ls 2>/dev/null)" -- "${cur}")) ;;
    rm) COMPREPLY=($(compgen -W "-f $(envx ls 2>/dev/null)" -- "${cur}")) ;;
    *) COMPREPLY=($(compgen -W "$(envx ls 2>/dev/null)" -- "${cur}")) ;;
    esac
    ;;
  *)
    case "${args[0]}" in
    get | set | rm)
      [ "${#args[@]}" -eq 2 ] &&
        COMPREPLY=($(compgen -W "$(envx _vars "${args[1]}" 2>/dev/null)" -- "${cur}"))
      ;;
    protect | unprotect | export)
      COMPREPLY=($(compgen -W "$(envx _vars "${args[1]}" 2>/dev/null)" -- "${cur}"))
      ;;
    run)
      COMPREPLY=($(compgen -W "-- $(envx _vars "${args[1]}" 2>/dev/null)" -- "${cur}"))
      ;;
    esac
    ;;
  esac
}

complete -o default -F _envx envx
