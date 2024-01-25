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
complex_path=karabiner/assets/complex_modifications
if [ -d $HOME/.config/$complex_path ]; then
	rm -rf $HOME/.config/$complex_path
fi
if [ -d $HOME/.config ]; then
	ln -s $HOME/$SETTINGS_DIR/$complex_path  $HOME/.config/$complex_path
else
	echo "no directory $HOME/.config"
fi


# bcomp (beyond compare command)
if [ -d "/mnt/c/Program Files/" ]; then
	# wsl
	ln -s $HOME/$SETTINGS_DIR/bcomp/.localbcomp.sh $HOME/.bcomp.sh
elif [ -d "/Applications/" ]; then
	ln -s $HOME/$SETTINGS_DIR/bcomp/.localbcomp.sh $HOME/.bcomp.sh
else
	ln -s $HOME/$SETTINGS_DIR/bcomp/.remotebcomp.sh $HOME/.bcomp.sh
fi

# wezterm
if [ -n "$(command -v wezterm)" ]; then
	ln -s $HOME/.dotfiles/wezterm/ $HOME/.config
	ln -s $HOME/$SETTINGS_DIR/wezterm/wezterm.lua $HOME/.wezterm.lua
fi


# hammerspoon
# ln -s $HOME/.dotfiles/.hammerspoon $HOME/.hammerspoon
# ln -s $HOME/$SETTINGS_DIR/.hammerspoon $HOME/.hammerspoon



# gdbinit
# ln -s $HOME/$SETTINGS_DIR/.gdbinit

# only linux workspace
# if [ "$1" == "linux" ]; then
# 	ln -s $HOME/$SETTINGS_DIR/.alias_waf
# fi


# google_drive linking
# googlemail="test@gmail.com"
# ln -s "$HOME/Library/CloudStorage/GoogleDrive-$(googlemail)/내 드라이브" "GoogleDrive"

