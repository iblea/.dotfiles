#!/bin/bash

SETTINGS_DIR=.dotfiles
# current path
SCRIPT_PATH=$(dirname $(realpath $0))

cd $HOME


# zsh
if [ ! -d $HOME/.zsh ]; then
	mkdir $HOME/.zsh/
fi
ln -s $HOME/$SETTINGS_DIR/.zshrc
ln -s $HOME/$SETTINGS_DIR/.zsh/.p10k.zsh $HOME/.zsh/.p10k.zsh

# bash
ln -s $HOME/$SETTINGS_DIR/.bashrc


# vimrc
ln -s $HOME/$SETTINGS_DIR/vimrc/.vimrc
cd $HOME/$SETTINGS_DIR
if [ -d ./.vim/ ]; then
	rm -rf ./.vim/
fi


# .vim setting

# tar -zxvf vim.tgz > /dev/null
# tar -zcvf vim.tgz .vim/
# cd $HOME
# ln -s $HOME/$SETTINGS_DIR/.vim

if [ ! -d $HOME/.vim ]; then
	mkdir $HOME/.vim/
fi

if [ ! -f $HOME/.vim/autoload/plug.vim ]; then
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "Please open vim and :PlugInstall first"


# envpath
ln -s $HOME/$SETTINGS_DIR/.envpath


# alias
ln -s $HOME/$SETTINGS_DIR/.aliases

# karabiner
if [[ "$(uname -s)" = "Darwin" ]]; then
	complex_path=karabiner/assets/complex_modifications
	if [ -d $HOME/.config/$complex_path ]; then
		rm -rf $HOME/.config/$complex_path
	fi
	if [ -d $HOME/.config ]; then
		ln -s $HOME/$SETTINGS_DIR/$complex_path  $HOME/.config/$complex_path
	else
		echo "no directory $HOME/.config"
	fi
fi


# bcomp (beyond compare command)
if [ -n "$(uname -r | grep 'WSL')" ]; then
	# wsl
	ln -s $HOME/$SETTINGS_DIR/bcomp/.localbcomp.sh $HOME/.bcomp.sh
elif [[ "$(uname -s)" = "Darwin" ]]; then
	ln -s $HOME/$SETTINGS_DIR/bcomp/.localbcomp.sh $HOME/.bcomp.sh
else
	ln -s $HOME/$SETTINGS_DIR/bcomp/.remotebcomp.sh $HOME/.bcomp.sh
fi

# wezterm
if [ -n "$(command -v wezterm)" ]; then
	ln -s $HOME/.dotfiles/wezterm_config/wezterm $HOME/.config
	ln -s $HOME/$SETTINGS_DIR/wezterm_config/wezterm/wezterm.lua $HOME/.wezterm.lua
fi


# hammerspoon
if [[ "$(uname -s)" = "Darwin" ]]; then
	ln -s $HOME/.dotfiles/.hammerspoon $HOME/.hammerspoon
	ln -s $HOME/$SETTINGS_DIR/.hammerspoon $HOME/.hammerspoon
fi



# gdbinit
# ln -s $HOME/$SETTINGS_DIR/.gdbinit

# only linux workspace
# if [ "$1" == "linux" ]; then
# 	ln -s $HOME/$SETTINGS_DIR/.alias_waf
# fi


# google_drive linking
# google drive linking
# gmail="test@gmail.com"
# ln -s "$HOME/Library/CloudStorage/GoogleDrive-$(gmail)/내 드라이브" "GoogleDrive"

