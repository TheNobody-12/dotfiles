#!/usr/bin/env bash

# Signature for version tracking
# VERSION: 2.3

JQ="/usr/bin/jq"
RMPC="/run/current-system/sw/bin/rmpc"
STATE_FILE="/tmp/sketchybar_mediaremote.json"
MAX_TITLE=25

truncate_text() {
  local text="$1"
  if [ ${#text} -gt $MAX_TITLE ]; then
    echo "${text:0:$MAX_TITLE}..."
  else
    echo "$text"
  fi
}

# Start background listener if requested
if [ "${1:-}" = "listen" ]; then
  MC="/opt/homebrew/bin/media-control"
  if [ -x "$MC" ]; then
    "$MC" stream --no-diff | while read -r line; do
       echo "$line" > "$STATE_FILE"
       sketchybar --trigger media_change
    done
  fi
  exit 0
fi

# --- MAIN PLUGIN LOGIC ---

# Gather states
RMPC_STATE=""
if [ -x "$RMPC" ]; then
  RMPC_STATUS="$("$RMPC" status 2>/dev/null)"
  if [ -n "$RMPC_STATUS" ] && ! echo "$RMPC_STATUS" | grep -q "GenericError"; then
    RMPC_STATE=$(echo "$RMPC_STATUS" | "$JQ" -r '.state // empty')
  fi
fi

BR_STATE="false"
BR_TITLE=""
BR_ARTIST=""
BR_APP=""
if [ -f "$STATE_FILE" ]; then
  RAW=$(cat "$STATE_FILE")
  BR_TITLE=$(echo "$RAW" | "$JQ" -r '.payload.title // empty')
  BR_ARTIST=$(echo "$RAW" | "$JQ" -r '.payload.artist // empty')
  BR_STATE=$(echo "$RAW" | "$JQ" -r '.payload.playing // "false"')
  BR_APP=$(echo "$RAW" | "$JQ" -r '.payload.bundleIdentifier // empty')
fi

# Determine icons based on app
get_icon() {
  local app="$1"
  case "$app" in
    *"mullvad"*|*"browser"*|*"firefox"*|*"safari"*|*"chrome"*) echo "󰖟" ;;
    *"mpv"*) echo "󰐊" ;;
    *"music"*) echo "󰝚" ;;
    *) echo "󰝚" ;;
  esac
}

# 1. Prioritize ANY ACTIVE PLAYBACK
if [ "$RMPC_STATE" = "Play" ]; then
  SONG="$("$RMPC" song 2>/dev/null)"
  TITLE=$(echo "$SONG" | "$JQ" -r '.metadata.title // .file | split("/") | last')
  ARTIST=$(echo "$SONG" | "$JQ" -r '.metadata.artist // empty')
  LABEL=$(truncate_text "$TITLE")
  if [ -n "$ARTIST" ] && [ "$ARTIST" != "null" ]; then LABEL="$LABEL - $(truncate_text "$ARTIST")"; fi
  sketchybar --set media icon="󰝚" label="$LABEL" drawing=on
  exit 0
fi

if [ "$BR_STATE" = "true" ] && [ -n "$BR_TITLE" ]; then
  ICON=$(get_icon "$BR_APP")
  LABEL=$(truncate_text "$BR_TITLE")
  if [ -n "$BR_ARTIST" ] && [ "$BR_ARTIST" != "null" ]; then LABEL="$LABEL - $(truncate_text "$BR_ARTIST")"; fi
  sketchybar --set media icon="$ICON" label="$LABEL" drawing=on
  exit 0
fi

# 2. Secondary: ANY PAUSED playback
if [ "$RMPC_STATE" = "Pause" ]; then
  SONG="$("$RMPC" song 2>/dev/null)"
  TITLE=$(echo "$SONG" | "$JQ" -r '.metadata.title // .file | split("/") | last')
  ARTIST=$(echo "$SONG" | "$JQ" -r '.metadata.artist // empty')
  LABEL=$(truncate_text "$TITLE")
  if [ -n "$ARTIST" ] && [ "$ARTIST" != "null" ]; then LABEL="$LABEL - $(truncate_text "$ARTIST")"; fi
  sketchybar --set media icon="󰏤" label="$LABEL" drawing=on
  exit 0
fi

if [ -n "$BR_TITLE" ]; then
  ICON=$(get_icon "$BR_APP")
  LABEL=$(truncate_text "$BR_TITLE")
  if [ -n "$BR_ARTIST" ] && [ "$BR_ARTIST" != "null" ]; then LABEL="$LABEL - $(truncate_text "$BR_ARTIST")"; fi
  sketchybar --set media icon="󰏤" label="$LABEL" drawing=on
  exit 0
fi

# Fallback: Hide
sketchybar --set media drawing=off
