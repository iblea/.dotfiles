#!/bin/bash

# if [ $# -le 0 ]; then
# 	echo "Usage: $0 <backup home path>"
# 	echo "example: $0 \"/home/test\""
# 	exit 0
# fi


HOME_PATH=""
SED_FLAG="___DOTFILES_SED_HOME_CONFIG___"
SKIP_WARNING=0

if [ $# -ne 0 ]; then
	if [[ "$1" = "-y" ]] || [[ "$1" = "--yes" ]]; then
		SKIP_WARNING=1
		shift
	fi
fi

if [ $# -eq 0 ]; then
	HOME_PATH="$HOME"
else
	HOME_PATH="$1"
fi

if [ $SKIP_WARNING -eq 0 ]; then
	echo "home path: '$HOME_PATH'"
	echo "WARNING: THIS SCRIPT IS **BACKUP** SCRIPT!!!"
	read -s -n1 -p "really backup? (y/n): " answer
	echo
	if [[ "$answer" = "Y" ]]; then
		answer="y"
	fi
	if [[ "$answer" != "y" ]] && [[ "$answer" != "yes" ]]; then
		exit 0
	fi
fi


curpath=$(dirname "$(realpath $0)")
cd "$curpath"

CLAUDE_PLUGINS_PATH="$HOME/.claude/plugins"
if [ ! -d "$CLAUDE_PLUGINS_PATH" ]; then
	echo "ERROR: no plugins data"
	exit 1
fi


cp -r "$CLAUDE_PLUGINS_PATH/installed_plugins.json" ./
cp -r "$CLAUDE_PLUGINS_PATH/known_marketplaces.json" ./

sed -i "s|$HOME_PATH|$SED_FLAG|" ./installed_plugins.json
sed -i "s|$HOME_PATH|$SED_FLAG|" ./known_marketplaces.json

