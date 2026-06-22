#!/usr/bin/env zsh

FONT_FACE="JetBrainsMono Nerd Font"

sketchybar --set $NAME label="$(date '+%a %b %-d %-H:%M')" label.font="$FONT_FACE:Bold:12.0"
