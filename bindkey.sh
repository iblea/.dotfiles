



if grep -q "/zsh" <<< "$SHELL"; then

	if [ -n "$ZSH" ]; then

		bindkey "^J" "down-line-or-history"
		bindkey "^K" "up-line-or-history"

		bindkey "^X" "backward-delete-char"
		bindkey "^A" "backward-char"
		bindkey "^D" "forward-char"
		bindkey "^W" "forward-word"
		bindkey "^T" "backward-word"
		bindkey "^U" "backward-word"
		bindkey "^F" "forward-char"
		bindkey "^B" "backward-char"
		bindkey "^N" "accept-line"
		bindkey "^O" "beginning-of-line"

	fi

elif grep -q "/bash" <<< "$SHELL"; then

    bind '"\C-k": previous-history'
    bind '"\C-j": next-history'

	bind '"\C-x": backward-delete-char'
	bind '"\C-a": backward-char'
	bind '"\C-d": forward-char'
	bind '"\C-w": forward-word'
	bind '"\C-t": backward-word'
	bind '"\C-u": backward-word'
	bind '"\C-f": forward-char'
	bind '"\C-b": backward-char'
	bind '"\C-n": accept-line'
	bind '"\C-o": beginning-of-line'

fi
