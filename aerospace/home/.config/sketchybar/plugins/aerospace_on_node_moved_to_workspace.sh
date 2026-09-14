#!/usr/bin/env bash

POSSIBLE_WORKSPACES_ORDERED=(A Z E R T Y U I O P Q S D F G H J K L M W X C V B N)
UNSELECTED_WORKSPACE_BACKGROUND_COLOR=0x00000000
workspace="$WORKSPACE"

# Add the workspace to sketchybar (if it didn't exist)...
sketchybar --add item "$workspace" left >/dev/null 2>&1 || true
sketchybar --set "$workspace" \
  background.color="$UNSELECTED_WORKSPACE_BACKGROUND_COLOR" \
  background.border_color=0xffd8dee9 \
  background.border_width=1 \
  background.corner_radius=5 \
  background.height=20 \
  background.drawing=on \
  label="$workspace" \
  padding_right=5 \
  label.padding_left=10 \
  label.padding_right=10 \
  click_script="aerospace workspace $workspace"

sketchybar --reorder "${POSSIBLE_WORKSPACES_ORDERED[@]}" >/dev/null 2>&1 || true
