#!/bin/bash

SETTINGS_DIR=dotfiles
# current path
SCRIPT_PATH=$(dirname $(realpath $0))

cd $HOME


# zsh
if [ ! -d $HOME/.zsh ]; then
	mkdir $HOME/.zsh/
fi
ln -s $HOME/$SETTINGS_DIR/.zshrc
ln -s $HOME/$SETTINGS_DIR/.zsh/.p10k.zsh $HOME/.zsh/.p10k.zsh


# vim
ln -s $HOME/$SETTINGS_DIR/vimrc/.vimrc
cd $HOME/$SETTINGS_DIR
if [ -d ./.vim/ ]; then
	rm -rf ./.vim/
fi
tar -zxf vim.tgz > /dev/null
# tar -zcvf vim.tgz .vim/
cd $HOME
ln -s $HOME/$SETTINGS_DIR/.vim


# alias
ln -s $HOME/$SETTINGS_DIR/.aliases


# bcomp (beyond compare command)
if [ -d "/mnt/c/Program Files/" ]; then
	# wsl
	ln -s $HOME/$SETTINGS_DIR/bcomp/.localbcomp.sh $HOME/.bcomp.sh
fi



# gdbinit
# ln -s $HOME/$SETTINGS_DIR/.gdbinit

# only linux workspace
# if [ "$1" == "linux" ]; then
# 	ln -s $HOME/$SETTINGS_DIR/.alias_waf
# fi

