# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
export ZDOTDIR="$HOME/.zsh/zcomp"
if [ ! -d "$ZDOTDIR" ]; then
    mkdir -p "$ZDOTDIR"
fi
if [ ! -e "$ZDOTDIR/.zshrc" ]; then
    if [ -L "$ZDOTDIR/.zshrc" ]; then
        # but linking file exists
        /bin/rm -f "$ZDOTDIR/.zshrc"
    fi
    ln -s "$HOME/.zshrc" "$ZDOTDIR/.zshrc"
fi

