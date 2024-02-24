#!/bin/bash

SETTINGS_DIR=.dotfiles
# current path
SCRIPT_PATH=$(dirname $(realpath $0))

cd $HOME

settings_full_dir=""
fixed_home=""
home_last=$(echo "${HOME:${#HOME}-1:1}")

if [ $? -ne 0 ]; then
	echo "Error: HOME is not set"
	echo "home evn : '$HOME'"
	exit 1
fi

if [ "$home_last" != "/" ]; then
	settings_full_dir="${HOME}/${SETTINGS_DIR}"
	fixed_home="$HOME"
else
	settings_full_dir="${HOME}${SETTINGS_DIR}"
	fixed_home="${HOME:0:${#HOME}-1}"
	if [ $? -ne 0 ]; then
		echo "Error: HOME is not set"
		echo "home evn : '$HOME'"
		exit 1
	fi
fi


echo "settings_full_dir: $settings_full_dir"

if [ -z "$settings_full_dir" ]; then
	echo "Error: settings_full_dir is not set"
	exit 1
fi


# zsh
if [ ! -d $fixed_home/.zsh ]; then
	mkdir $fixed_home/.zsh/
fi
ln -s $settings_full_dir/.zshrc
ln -s $settings_full_dir/.zsh/.p10k.zsh $fixed_home/.zsh/.p10k.zsh

# bash
ln -s $settings_full_dir/.bashrc


# vimrc
ln -s $settings_full_dir/vimrc/.vimrc
cd $settings_full_dir
if [ -d ./.vim/ ]; then
	rm -rf ./.vim/
fi


# .vim setting

# tar -zxvf vim.tgz > /dev/null
# tar -zcvf vim.tgz .vim/
# cd $HOME
# ln -s $settings_full_dir/.vim

if [ ! -d $fixed_home/.vim ]; then
	mkdir $fixed_home/.vim/
fi

if [ ! -f $fixed_home/.vim/autoload/plug.vim ]; then
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "Please open vim and :PlugInstall first"


# envpath
cd $HOME
ln -s $settings_full_dir/.envpath


# alias
ln -s $settings_full_dir/.aliases


# karabiner
if [[ "$(uname -s)" = "Darwin" ]]; then
	complex_path=karabiner/assets/complex_modifications
	if [ -d $fixed_home/.config/$complex_path ]; then
		rm -rf $fixed_home/.config/$complex_path
	fi
	if [ -d $fixed_home/.config ]; then
		ln -s $settings_full_dir/$complex_path  $fixed_home/.config/$complex_path
	else
		echo "no directory $fixed_home/.config"
	fi
fi


# bcomp (beyond compare command)
if [ -n "$(uname -r | grep 'WSL')" ]; then
	# wsl
	ln -s $settings_full_dir/bcomp/.localbcomp.sh $fixed_home/.bcomp.sh
elif [[ "$(uname -s)" = "Darwin" ]]; then
	ln -s $settings_full_dir/bcomp/.localbcomp.sh $fixed_home/.bcomp.sh
else
	ln -s $settings_full_dir/bcomp/.remotebcomp.sh $fixed_home/.bcomp.sh
fi

# wezterm
if [ -n "$(command -v wezterm)" ]; then
	ln -s $fixed_home/.dotfiles/wezterm_config/wezterm $fixed_home/.config
	ln -s $settings_full_dir/wezterm_config/wezterm/wezterm.lua $fixed_home/.wezterm.lua
fi


# hammerspoon
if [[ "$(uname -s)" = "Darwin" ]]; then
	ln -s $fixed_home/.dotfiles/.hammerspoon $fixed_home/.hammerspoon
	ln -s $settings_full_dir/.hammerspoon $fixed_home/.hammerspoon
fi

if [ -n "$(command -v sgpt)" ]; then
	SHELL_GPT_DIR=$HOME/.config/shell_gpt
	if [ ! -d $SHELL_GPT_DIR/ ]; then
		mkdir -p $SHELL_GPT_DIR/
	fi
	if [ ! -f $SHELL_GPT_DIR/.sgptrc ]; then
		cp -rfp $settings_full_dir/.sgptrc $SHELL_GPT_DIR/.sgptrc
		echo "Please set openai api key"
	fi
fi



# gdbinit
# ln -s $settings_full_dir/.gdbinit

# only linux workspace
# if [ "$1" == "linux" ]; then
# 	ln -s $settings_full_dir/.alias_waf
# fi


# google_drive linking
# google drive linking
# gmail="test@gmail.com"
# ln -s "$fixed_home/Library/CloudStorage/GoogleDrive-$(gmail)/내 드라이브" "GoogleDrive"

