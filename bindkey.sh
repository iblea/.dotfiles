



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

	bindkey "\C-x" "backward-delete-char"
	bindkey "\C-a" "backward-char"
	bindkey "\C-d" "forward-char"
	bindkey "\C-w" "forward-word"
	bindkey "\C-t" "backward-word"
	bindkey "\C-u" "backward-word"
	bindkey "\C-f" "forward-char"
	bindkey "\C-b" "backward-char"
	bindkey "\C-n" "accept-line"
	bindkey "\C-o" "beginning-of-line"

fi
