#!/usr/bin/env sh

# Network plugin for sketchybar
# Shows Wi-Fi status

IP_ADDRESS=$(ipconfig getifaddr en0)

if [ -z "$IP_ADDRESS" ]; then
  sketchybar --set $NAME icon="󰤭" label="Disconnected" icon.color=0xffcc241d
else
  sketchybar --set $NAME icon="󰤨" label="Connected" icon.color=0xffb8bb26
fi
