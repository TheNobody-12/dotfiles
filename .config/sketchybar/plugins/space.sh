#!/usr/bin/env sh
# Load Theme colors if available
THEME_FILE="$HOME/.config/themes/current/shellcolors.sh"
if [ -r "$THEME_FILE" ]; then
  source "$THEME_FILE"
else
  ACTIVE=0xfffe8019
fi

YABAI="/run/current-system/sw/bin/yabai"
JQ="/usr/bin/jq"

# Ensure SID is set (sometimes it might not be passed correctly in triggers)
if [ -z "$SID" ]; then
  SID="${NAME#space.}"
fi

if [ "$SELECTED" = "true" ]; then
  sketchybar --set "$NAME" background.drawing=on \
                           background.color="$ACTIVE" \
                           icon.color=0xff111111 \
                           icon=""
else
  sketchybar --set "$NAME" background.drawing=on \
                           background.color=0x00000000 \
                           icon.color=0xffebdbb2 \
                           icon=""
fi

# We will hide the label (window icons) for a cleaner minimalist look
sketchybar --set "$NAME" label.drawing=off

