#!/bin/bash


cd $HOME/.config/aider/

/opt/homebrew/bin/aider \
	-c $HOME/.config/aider/.aider.conf.yml \
	--input-history-file "$HOME/.config/aider/history.input.md" \
	--chat-history-file "$HOME/.config/aider/history.chat.md" \
	--no-git \
	--no-gitignore \
	--dark-mode
