#!/usr/bin/env sh

SKETCHYBAR="/run/current-system/sw/bin/sketchybar"
YABAI="/run/current-system/sw/bin/yabai"
JQ="/usr/bin/jq"
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

# Debounce: if another instance is running, exit
LOCKFILE="/tmp/sketchybar_space_refresh.lock"
if [ -f "$LOCKFILE" ]; then
  PID=$(cat "$LOCKFILE" 2>/dev/null)
  if kill -0 "$PID" 2>/dev/null; then
    exit 0
  fi
fi
echo $$ > "$LOCKFILE"

# Small delay to batch rapid successive events
sleep 0.15

# 1. Get current spaces from yabai
SPACES=$("$YABAI" -m query --spaces | "$JQ" -r '.[].index')

# 2. Get existing space items in sketchybar
BAR_ITEMS=$("$SKETCHYBAR" --query bar)
EXISTING_SPACES=$(echo "$BAR_ITEMS" | "$JQ" -r '.items[] | select(startswith("space."))')

# 3. Add missing spaces
for i in $SPACES; do
    if ! echo "$EXISTING_SPACES" | grep -q "space.$i"; then
        "$SKETCHYBAR" --add space space."$i" left \
                   --set space."$i" space="$i" \
                                     icon="$i" \
                                     label.drawing=off \
                                     background.drawing=on \
                                     background.color=0x00000000 \
                                     script="$PLUGIN_DIR/space.sh" \
                                     click_script="$YABAI -m space --focus $i" \
                   --subscribe space."$i" window_change space_change front_app_switched
    fi
done

# 4. Remove extra spaces
for item in $EXISTING_SPACES; do
    idx="${item#space.}"
    if ! echo "$SPACES" | grep -q "^$idx$"; then
        "$SKETCHYBAR" --remove "$item"
    fi
done

# 5. Fix ordering
ALL_ITEMS=$("$SKETCHYBAR" --query bar | "$JQ" -r '.items[]')
ORDERED_SPACES=$(echo "$ALL_ITEMS" | grep "^space\." | sort -V | tr '\n' ' ')
OTHER_ITEMS=$(echo "$ALL_ITEMS" | grep -v "^space\." | tr '\n' ' ')

"$SKETCHYBAR" --reorder $ORDERED_SPACES $OTHER_ITEMS

# 6. Trigger update
"$SKETCHYBAR" --trigger window_change

rm -f "$LOCKFILE"
