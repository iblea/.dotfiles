
if [ -n "$(echo $- | grep 'i')" ]; then

set_o=$(set -o)
emacs_mode=$(echo "$set_o" | grep "emacs" | awk '{ print $NF }')
vi_mode=$(echo "$set_o" | grep "vi " | awk '{ print $NF }')

if [[ "$emacs_mode" != "off" ]] || [[ "$vi_mode" != "off" ]]; then

# shell=$(ps -p $$ -o 'comm=')
shell=$(echo $0)
echo "$shell"


if grep -q "zsh" <<< "$shell"; then
	if [ -n "$ZSH" ]; then

		source $HOME/.dotfiles/bindkey/zsh_bindkey.sh

	fi

elif grep -q "bash" <<< "$shell"; then

	source $HOME/.dotfiles/bindkey/bash_bindkey.sh

fi

fi

fi

