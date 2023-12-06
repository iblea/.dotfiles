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


# vim
ln -s $HOME/$SETTINGS_DIR/vimrc/.vimrc
cd $HOME/$SETTINGS_DIR
if [ -d ./.vim/ ]; then
	rm -rf ./.vim/
fi
tar -zxvf vim.tgz > /dev/null
# tar -zcvf vim.tgz .vim/

# vim plugin
echo "setting vim plugin to download in github"
./.vim/vimplugin.sh

cd $HOME
ln -s $HOME/$SETTINGS_DIR/.vim


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

# hammerspoon
# ln -s $HOME/.dotfiles/.hammerspoon $HOME/.hammerspoon
# ln -s $HOME/$SETTINGS_DIR/.hammerspoon $HOME/.hammerspoon



# gdbinit
# ln -s $HOME/$SETTINGS_DIR/.gdbinit

# only linux workspace
# if [ "$1" == "linux" ]; then
# 	ln -s $HOME/$SETTINGS_DIR/.alias_waf
# fi

