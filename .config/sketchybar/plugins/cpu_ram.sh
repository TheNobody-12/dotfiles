#!/usr/bin/env sh

CPU=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.0f", s/8}')
RAM=$(ps -A -o rss | awk '{s+=$1} END {printf "%.0f", s/1024/1024}')

sketchybar --set cpu_ram label="CPU ${CPU}%  RAM ${RAM}GB"
