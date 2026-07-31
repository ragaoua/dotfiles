# Enable ghostty's shell integration (adds OSC 133 metadata/markers to the
# terminal stream), specifically to allow Tmux to jump between shell prompts
if [[ -n ${GHOSTTY_RESOURCES_DIR:-} ]]; then
  source "$GHOSTTY_RESOURCES_DIR/shell-integration/bash/ghostty.bash"
fi
