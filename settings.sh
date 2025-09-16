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
echo

if [ -z "$settings_full_dir" ]; then
    echo "Error: settings_full_dir is not set"
    exit 1
fi


# zsh
if [ ! -d $fixed_home/.zsh ]; then
    mkdir $fixed_home/.zsh/
fi


# set rcfile
rc_files=(
    ".zshrc" ".zshrc"
    ".zshenv" ".zshenv"
    ".zsh/.p10k.zsh" ".zsh/.p10k.zsh"
    ".bashrc" ".bashrc"
    "vimrc/.vimrc" ".vimrc"
    ".toprc" ".toprc"
)


for (( i=0; i<${#rc_files[@]}; i+=2 )); do
    settings_path="${rc_files[$i]}"
    home_linking_path="${rc_files[$i+1]}"

    echo "check rc_file: $settings_path -> $home_linking_path"

    # non file
    if [ ! -e "$fixed_home/$home_linking_path" ]; then
        if [ -L "$fixed_home/$home_linking_path" ]; then
            # but linking file exists
            rm -f "$fixed_home/$home_linking_path"
        fi
        ln -s "$settings_full_dir/$settings_path" "$fixed_home/$home_linking_path"
    fi
done

# https://github.com/neovim/neovim-releases (GLIBC 2.27 official unsupported)
if [ -n $(which nvim) ]; then
    echo "neovim settings"
    if [ ! -d "$fixed_home/.config" ]; then
        mkdir -p "$fixed_home/.config/"
    fi
    cd "$fixed_home/.config"
    if [ ! -d "$fixed_home/.config/nvim" ]; then
        if [ -L "$fixed_home/.config/nvim" ]; then
            rm -f "$fixed_home/.config/nvim"
        fi
        ln -s $settings_full_dir/vimrc/neovim nvim
    fi
    cd "$PARENT_DIR"
else
    echo "neovim is not installed"
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
cd "$fixed_home"

if [ ! -e "$fixed_home/.envpath" ]; then
    if [ -L "$fixed_home/.envpath" ]; then
        rm -f "$fixed_home/.envpath"
    fi
    ln -s $settings_full_dir/.envpath
fi


# alias
if [ ! -e "$fixed_home/.aliases" ]; then
    if [ -L "$fixed_home/.aliases" ]; then
        rm -f "$fixed_home/.aliases"
    fi
    ln -s $settings_full_dir/.aliases
fi


# karabiner
if [[ "$(uname -s)" = "Darwin" ]]; then
    complex_path=karabiner/assets/complex_modifications
    complex_parent_path="$(dirname $complex_path)"
    if [ ! -d "$fixed_home/.config/$complex_parent_path" ]; then
        mkdir -p "$fixed_home/.config/$complex_parent_path"
    fi
    if [ -d "$fixed_home/.config/$complex_path" ]; then
        rm -rf "$fixed_home/.config/$complex_path"
    fi
    if [ -L "$fixed_home/.config/$complex_path" ]; then
        rm -rf "$fixed_home/.config/$complex_path"
    fi
    if [ -d $fixed_home/.config ]; then
        ln -s $settings_full_dir/$complex_path  $fixed_home/.config/$complex_path
    else
        echo "no directory $fixed_home/.config"
    fi
fi


# bcomp (beyond compare command)
if [ ! -e "$fixed_home/.bcomp.sh" ]; then
    if [ -L "$fixed_home/.bcomp.sh" ]; then
        rm -f "$fixed_home/.bcomp.sh"
    fi

    if [ -n "$(uname -r | grep 'WSL')" ]; then
        # wsl
        ln -s $settings_full_dir/.bin/.localbcomp.sh $fixed_home/.bcomp.sh
    elif [[ "$(uname -s)" = "Darwin" ]]; then
        ln -s $settings_full_dir/.bin/.localbcomp.sh $fixed_home/.bcomp.sh
    else
        ln -s $settings_full_dir/.bin/.remotebcomp.sh $fixed_home/.bcomp.sh
    fi
fi

# wezterm
if [ -n "$(command -v wezterm)" ]; then
    if [ ! -e "$fixed_home/.config" ]; then
        if [ -L "$fixed_home/.config" ]; then
            rm -f "$fixed_home/.config"
        fi
        ln -s $fixed_home/.dotfiles/wezterm_config/wezterm $fixed_home/.config
    fi
    if [ ! -e "$fixed_home/.wezterm.lua" ]; then
        if [ -L "$fixed_home/.wezterm.lua" ]; then
            rm -f "$fixed_home/.wezterm.lua"
        fi
        ln -s $settings_full_dir/wezterm_config/wezterm/wezterm.lua $fixed_home/.wezterm.lua
    fi
fi


# hammerspoon
if [[ "$(uname -s)" = "Darwin" ]]; then
    if [ ! -e "$fixed_home/.hammerspoon" ]; then
        if [ -L "$fixed_home/.hammerspoon" ]; then
            rm -f "$fixed_home/.hammerspoon"
        fi
        ln -s $settings_full_dir/.hammerspoon $fixed_home/.hammerspoon
    fi
fi

if [ -n "$(command -v sgpt)" ]; then
    SHELL_GPT_DIR="$PARENT_DIR/.config/shell_gpt"
    if [ ! -d $SHELL_GPT_DIR/ ]; then
        mkdir -p $SHELL_GPT_DIR/
    fi
    if [ ! -f "$SHELL_GPT_DIR/.sgptrc" ]; then
        if [ -L "$SHELL_GPT_DIR/.sgptrc" ]; then
            rm -f "$SHELL_GPT_DIR/.sgptrc"
        fi
        cp -rfp "$settings_full_dir/.sgptrc" "$SHELL_GPT_DIR/.sgptrc"
        echo "Please set openai api key"
    fi
fi

# ghostty

if [[ "$(uname -s)" = "Darwin" ]]; then
if [ -d "$HOME/Library/Application Support/com.mitchellh.ghostty" ]; then
    rm -f "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    ln -s "$settings_full_dir/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
fi
fi

# if [ -z "$(command -v claude)" ]; then
#     if [ ! -d "$HOME/.claude" ]; then
#         mkdir -p "$HOME/.claude"
#     fi
#     ln -s "$HOME/.dotfiles/prompt/global_prompt.md" "$HOME/.claude/CLAUDE.md"
# fi


if [ -z "$(command -v codex)" ]; then
    if [ ! -d  "$HOME/.codex" ]; then
        mkdir -p "$HOME/.codex"
    fi
    ln -s "$HOME/.dotfiles/prompt/global_prompt.md" "$HOME/.codex/AGENTS.md"
fi


if [ -z "$(command -v opencode)" ]; then
    if [ ! -d  "$HOME/.config/opencode" ]; then
        mkdir -p "$HOME/.config/opencode"
    fi
    ln -s "$HOME/.dotfiles/prompt/global_prompt.md" "$HOME/.config/opencode/AGENTS.md"
fi

# zoxide
# curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# gdbinit
# ln -s $settings_full_dir/.gdbinit

# only linux workspace
# if [ "$1" == "linux" ]; then
#     ln -s $settings_full_dir/.alias_waf
# fi


# google_drive linking
# google drive linking
# gmail="test@gmail.com"
# ln -s "$fixed_home/Library/CloudStorage/GoogleDrive-$(gmail)/내 드라이브" "GoogleDrive"



echo ""
echo "done"
