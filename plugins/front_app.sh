#!/usr/bin/env zsh

ICON_PADDING_RIGHT=5

case $INFO in
"Helium")
    ICON_PADDING_RIGHT=5
    ICON=󰞍
    ;;
"Pluely")
    exit 0
    ;;
"RustDesk")
    exit 0
    ;;
"pluely")
    exit 0
    ;;
"truely")
    exit 0
    ;;
"Calendar")
    ICON_PADDING_RIGHT=3
    ICON=
    ;;
"Discord")
    ICON=
    ;;
"FaceTime")
    ICON_PADDING_RIGHT=5
    ICON=
    ;;
"Finder")
    ICON=󰀶
    ;;
"Firefox")
    ICON_PADDING_RIGHT=7
    ICON=󰈹
    ;;
"Ghostty")
    ICON=󰄛
    ;;
"Messages")
    ICON=
    ;;
"Obsidian")
    ICON_PADDING_RIGHT=6
    ICON=󰠮
    ;;
"Preview")
    ICON_PADDING_RIGHT=3
    ICON=
    ;;
"Spotify")
    ICON_PADDING_RIGHT=2
    ICON=
    ;;
"Beeper")
    ICON_PADDING_RIGHT=2
    ICON=󰛋
    ;;
"ChatGPT")
    ICON_PADDING_RIGHT=2
    ICON=󱜸
    ;;
"Mail")
    ICON_PADDING_RIGHT=2
    ICON=
    ;;
*)
    ICON_PADDING_RIGHT=2
    ICON=
    ;;
esac

sketchybar --set $NAME icon=$ICON icon.padding_right=$ICON_PADDING_RIGHT
sketchybar --set $NAME.name label="$INFO"
