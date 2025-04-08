#!/bin/bash

NOTE="$HOME/.notepad/note.md"
GUI_VI="/Applications/Obsidian.app/"

if [ ! -d "$GUI_VI" ]; then
	exit 1
fi

if [ ! -f "$NOTE" ]; then
	DIR_NAME="$(dirname $NOTE)"
	if [ ! -d "$DIR_NAME" ]; then
		mkdir -p "$DIR_NAME"
	fi
	touch "$NOTE"
fi

open -a "$GUI_VI" "$NOTE"

