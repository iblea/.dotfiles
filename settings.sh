#!/bin/bash

SETTINGS_DIR=.dotfiles
# current path
SCRIPT_PATH=$(dirname $(realpath $0))

# PARENT_DIR="$HOME"
PARENT_DIR=$(dirname "${SCRIPT_PATH}")

cd "$PARENT_DIR"


settings_full_dir=""
fixed_home=""
home_last=$(echo "${PARENT_DIR:${#PARENT_DIR}-1:1}")

if [ $? -ne 0 ]; then
	echo "Error: HOME is not set"
	echo "home evn : '$PARENT_DIR'"
	exit 1
fi

if [ "$home_last" != "/" ]; then
	settings_full_dir="${PARENT_DIR}/${SETTINGS_DIR}"
	fixed_home="$PARENT_DIR"
else
	settings_full_dir="${PARENT_DIR}${SETTINGS_DIR}"
	fixed_home="${PARENT_DIR:0:${#PARENT_DIR}-1}"
	if [ $? -ne 0 ]; then
		echo "Error: HOME is not set"
		echo "home evn : '$PARENT_DIR'"
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

# https://github.com/neovim/neovim-releases (GLIBC 2.27 official unsupported)
if [ -n $(which nvim) ]; then
    echo "neovim settings"
    if [ ! -d "$fixed_home/.config" ]; then
        mkdir -p "$fixed_home/.config/"
    fi
    cd "$fixed_home/.config"
    if [ ! -d "$fixed_home/.config/nvim" ]; then
        ln -s $settings_full_dir/vimrc/neovim nvim
    fi
    cd "$PARENT_DIR"
fi

cd $settings_full_dir
if [ -d ./.vim/ ]; then
	rm -rf ./.vim/
fi


# .vim setting

# tar -zxvf vim.tgz > /dev/null
# tar -zcvf vim.tgz .vim/
# cd $PARENT_DIR
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
cd "$PARENT_DIR"
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
	ln -s $settings_full_dir/.bin/.localbcomp.sh $fixed_home/.bcomp.sh
elif [[ "$(uname -s)" = "Darwin" ]]; then
	ln -s $settings_full_dir/.bin/.localbcomp.sh $fixed_home/.bcomp.sh
else
	ln -s $settings_full_dir/.bin/.remotebcomp.sh $fixed_home/.bcomp.sh
fi

# wezterm
if [ -n "$(command -v wezterm)" ]; then
	ln -s $fixed_home/.dotfiles/wezterm_config/wezterm $fixed_home/.config
	ln -s $settings_full_dir/wezterm_config/wezterm/wezterm.lua $fixed_home/.wezterm.lua
fi


# hammerspoon
if [[ "$(uname -s)" = "Darwin" ]]; then
	if [ ! -d "$fixed_home/.hammerspoon" ]; then
		ln -s $settings_full_dir/.hammerspoon $fixed_home/.hammerspoon
	fi
fi

if [ -n "$(command -v sgpt)" ]; then
	SHELL_GPT_DIR="$PARENT_DIR/.config/shell_gpt"
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

