#!/usr/bin/env bash

STATE_FILE="/tmp/sketchybar_mediaremote.json"
JQ="/usr/bin/jq"
RMPC="/etc/profiles/per-user/gravity/bin/rmpc"
MC="/opt/homebrew/bin/media-control"
MAX_TITLE=25

truncate_text() {
  local text="$1"
  if [ ${#text} -gt $MAX_TITLE ]; then
    echo "${text:0:$MAX_TITLE}..."
  else
    echo "$text"
  fi
}

# Background listener mode: streams MediaRemote events and triggers sketchybar
if [ "${1:-}" = "listen" ]; then
  if [ -x "$MC" ]; then
    "$MC" stream --no-diff | while IFS= read -r line; do
      # Deduplicate: only trigger on meaningful changes (title/artist/playing)
      if [ -f "$STATE_FILE" ]; then
        NEW_KEY=$(echo "$line" | "$JQ" -r '[.title,.artist,.playing] | @tsv' 2>/dev/null)
        OLD_KEY=$(cat "$STATE_FILE" | "$JQ" -r '[.title,.artist,.playing] | @tsv' 2>/dev/null)
        if [ "$NEW_KEY" = "$OLD_KEY" ]; then
          continue
        fi
      fi
      echo "$line" > "$STATE_FILE"
      sketchybar --trigger media_change
    done
  fi
  exit 0
fi

# Main plugin logic (called by sketchybar)

# 1. Check MPD (rmpc) first — highest priority, richest metadata
if [ -x "$RMPC" ]; then
  RMPC_STATUS=$("$RMPC" status 2>/dev/null)
  if [ -n "$RMPC_STATUS" ] && ! echo "$RMPC_STATUS" | grep -q "GenericError"; then
    RMPC_STATE=$(echo "$RMPC_STATUS" | "$JQ" -r '.state // empty')
    if [ "$RMPC_STATE" = "Play" ] || [ "$RMPC_STATE" = "Pause" ]; then
      SONG=$("$RMPC" song 2>/dev/null)
      TITLE=$(echo "$SONG" | "$JQ" -r '.metadata.title // .file | split("/") | last')
      ARTIST=$(echo "$SONG" | "$JQ" -r '.metadata.artist // empty')
      LABEL=$(truncate_text "$TITLE")
      if [ -n "$ARTIST" ] && [ "$ARTIST" != "null" ]; then
        LABEL="$LABEL - $(truncate_text "$ARTIST")"
      fi
      if [ "$RMPC_STATE" = "Play" ]; then
        sketchybar --set media icon="󰝚" label="$LABEL" drawing=on
      else
        sketchybar --set media icon="󰏤" label="$LABEL" drawing=on
      fi
      exit 0
    fi
  fi
fi

# 2. Fallback: macOS MediaRemote state file (populated by background listener)
if [ -f "$STATE_FILE" ]; then
  RAW=$(cat "$STATE_FILE")
  if [ -n "$RAW" ]; then
    PLAYING=$(echo "$RAW" | "$JQ" -r '.playing // false')
    TITLE=$(echo "$RAW" | "$JQ" -r '.title // empty')
    ARTIST=$(echo "$RAW" | "$JQ" -r '.artist // empty')
    BUNDLE=$(echo "$RAW" | "$JQ" -r '.bundleIdentifier // empty')

    # Simplify generic browser placeholders instead of hiding them
    case "$TITLE" in
      *"is playing media")
        TITLE="Browser"
        ARTIST=""
        ;;
    esac

    if [ "$PLAYING" = "true" ] && [ -n "$TITLE" ]; then
      LABEL=$(truncate_text "$TITLE")
      if [ -n "$ARTIST" ] && [ "$ARTIST" != "null" ]; then
        LABEL="$LABEL - $(truncate_text "$ARTIST")"
      fi

      case "$BUNDLE" in
        *mullvad*) ICON="󰖟" ;;
        *safari*) ICON="󰖟" ;;
        *firefox*) ICON="󰖟" ;;
        *chrome*) ICON="󰖟" ;;
        *music*) ICON="󰝚" ;;
        *spotify*) ICON="󰓇" ;;
        *) ICON="󰝚" ;;
      esac

      sketchybar --set media icon="$ICON" label="$LABEL" drawing=on
      exit 0
    fi

    # Show paused state if there's a title
    if [ -n "$TITLE" ]; then
      LABEL=$(truncate_text "$TITLE")
      if [ -n "$ARTIST" ] && [ "$ARTIST" != "null" ]; then
        LABEL="$LABEL - $(truncate_text "$ARTIST")"
      fi
      sketchybar --set media icon="󰏤" label="$LABEL" drawing=on
      exit 0
    fi
  fi
fi

# Fallback: hide
sketchybar --set media drawing=off
