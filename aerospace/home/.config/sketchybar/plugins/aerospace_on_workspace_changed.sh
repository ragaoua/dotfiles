#!/usr/bin/env bash

POSSIBLE_WORKSPACES_ORDERED=(A Z E R T Y U I O P Q S D F G H J K L M W X C V B N)
UNSELECTED_WORKSPACE_BACKGROUND_COLOR=0x00000000
SELECTED_WORKSPACE_BACKGROUND_COLOR=0x44ffffff

workspaces=($(aerospace list-workspaces --all))
previous_workspace="$PREVIOUS_WORKSPACE"
current_workspace="$CURRENT_WORKSPACE"

if [[ ! " ${workspaces[*]} " =~ " $previous_workspace " ]]; then
  # Remove the previous workspace if it disappeared from aerospace...
  sketchybar --remove "$previous_workspace" >/dev/null 2>&1 || true
else
  # ...else, redraw it to clear the highlighting
  sketchybar --set "$previous_workspace" \
    background.color="$UNSELECTED_WORKSPACE_BACKGROUND_COLOR" \
    background.border_color=0xffd8dee9 \
    background.border_width=1 \
    background.corner_radius=5 \
    background.height=20 \
    background.drawing=on \
    label="$previous_workspace" \
    padding_right=5 \
    label.padding_left=10 \
    label.padding_right=10 \
    click_script="aerospace workspace $previous_workspace"
fi

# Add the current_workspace to sketchybar (if it didn't exist)...
sketchybar --add item "$current_workspace" left >/dev/null 2>&1 || true
# ...then (re)draw it to hightlight it
sketchybar --set "$current_workspace" \
  background.color="$SELECTED_WORKSPACE_BACKGROUND_COLOR" \
  background.border_color=0xffd8dee9 \
  background.border_width=1 \
  background.corner_radius=5 \
  background.height=20 \
  background.drawing=on \
  label="$current_workspace" \
  padding_right=5 \
  label.padding_left=10 \
  label.padding_right=10 \
  click_script="aerospace workspace $current_workspace"

sketchybar --reorder "${POSSIBLE_WORKSPACES_ORDERED[@]}" >/dev/null 2>&1 || true
