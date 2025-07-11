
# environment path (envpath)
if [ -f $HOME/.envpath ]; then
    # . ~/.envpath
    source ~/.envpath
fi

# into /etc/zsh/zshrc (vscode terminal)
# # Useful support for interacting with Terminal.app or other terminal programs
# if [ -r "/etc/zsh/zshrc_$TERM_PROGRAM" ]; then
#     . "/etc/zsh/zshrc_$TERM_PROGRAM"
# else
#     . "/etc/zsh/zshrc_default"
# fi

# /etc/zsh/zshrc_default / zshrc_vscode
# source $HOME/.zshrc

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
# need mkdir ~/.zsh
# ### install oh-my-zsh
# curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | /bin/bash -
# mv ~/.oh-my-zsh ~/.zsh/
# ### install powerlevel10k (p10k)
# git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.zsh/.oh-my-zsh/custom/themes/powerlevel10k
export ZSH="$HOME/.zsh/.oh-my-zsh"
export TERM=xterm-256color


# zsh-syntax-highlighting plugin
if [ ! -d $ZSH/custom/plugins/zsh-syntax-highlighting/ ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH/custom/plugins/zsh-syntax-highlighting
fi

# zsh-autosuggestions plugin
if [ ! -d $ZSH/custom/plugins/zsh-autosuggestions/ ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH/custom/plugins/zsh-autosuggestions/
fi

if [ ! -d $ZSH/custom/plugins/git-open/ ]; then
    # git clone https://github.com/paulirish/git-open.git $ZSH/custom/plugins/git-open/
    git clone https://github.com/iblea/git-open.git $ZSH/custom/plugins/git-open/
fi




# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
export ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.


plugins=(
    "git"
    "git-open"
    "zsh-syntax-highlighting"
    "zsh-autosuggestions"
)


# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8
if [ -z "$( locale -a 2>/dev/null | grep "${LC_ALL}" )" ]; then
    export LC_ALL=""
fi

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if [ ! -d $HOME/.zsh/zcomp/ ]; then
    mkdir -p $HOME/.zsh/zcomp/
fi
export ZDOTDIR="$HOME/.zsh/zcomp"

# export setting
export HISTFILE="$HOME/.zsh/.zsh_history"
export LESS=-FRX

if [ -d /mnt/c/Users/ghkd0 ]; then
    export WINHOME=/mnt/c/Users/ghkd0
    export SSLKEYLOGFILE=$WINHOME/sslkeylog.log
else
    export SSLKEYLOGFILE=$HOME/sslkeylog.log
fi

# ruby
# export GEM_HOME=$HOME/gems
# export PATH=$HOME/gems/bin:$PATH


# setopt autolist
# setopt noautomenu


# git ssh (passwd modify user)
# git config --global core.sshCommand "ssh -i $HOME/.ssh/id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
# gitssh_path=$HOME/.ssh/.gitssh.sh
#
# if [[ ! -f $gitssh_path ]]; then
#     touch $gitssh_path
#     echo -e "#/bin/bash" >> $gitssh_path
#     echo "" >> $gitssh_path
#     echo "ssh -F ~/.ssh/config -i ~/.ssh/id_rsa \$*" >> $gitssh_path
# fi
#
# if [[ ! -x $gitssh_path ]]; then
#     chmod 755 $gitssh_path
# fi

# export GIT_SSH=$gitssh_path
# GIT_SSH_COMMAND='ssh -i $HOME/.ssh/id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'

# oh-my-zsh options
DISABLE_MAGIC_FUNCTIONS=true

# oh-my-zsh
if ! (declare -f -F "is_plugin" > /dev/null); then
    source $ZSH/oh-my-zsh.sh
fi

# remove oh-my-zsh options variables
unset DISABLE_MAGIC_FUNCTIONS

# p10k
if [[ ! -v POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS ]]; then
    [[ -f ~/.zsh/.p10k.zsh ]] && source ~/.zsh/.p10k.zsh
    # [[ ! -f ~/.zsh/.p10k.zsh ]] || source ~/.zsh/.p10k.zsh
fi


if [ -d $HOME/.dotfiles/env_custom/ ]; then
    local files=( $(find $HOME/.dotfiles/env_custom/ -type f -not -name '.gitkeep') )
    for file in $files; do
        . $file
    done
fi

ZOXIDE_PATH=$(command -v zoxide)
if [ -n "$ZOXIDE_PATH" ]; then
    export _ZO_DATA_DIR="$HOME/.local/share/zoxide"
    export _ZO_ECHO=1
    export _ZO_MAXAGE=10000
    if [ ! -d "$_ZO_DATA_DIR" ]; then
        mkdir -p "$_ZO_DATA_DIR"
    fi
    eval "$($ZOXIDE_PATH init zsh --cmd cd --hook prompt)"
fi
unset ZOXIDE_PATH

# ### install fd
# https://github.com/sharkdp/fd/releases
# wget --no-check-certificate -O fd_pkg.deb <url>
# sudo dpkg -i fd_pkg.deb && rm -f fd_pkg.deb
#
# ### install fzf
# git clone --depth 1 https://github.com/junegunn/fzf.git ~/.zsh/.fzf
# ~/.zsh/.fzf/install
# ---------
if [ "$(command -v fzf)" = "" ]; then
    if [ -d $HOME/.zsh/.fzf/ ]; then
        # if [[ ! "$PATH" == *${HOME}/.zsh/.fzf/bin* ]]; then fi
        if ! grep -q "$HOME/.zsh/.fzf/bin" <<< "$PATH"; then
            export PATH="$HOME/.zsh/.fzf/bin:$PATH"
        fi
    fi
fi
if [ -n "$(command -v fzf)" ]; then
    # export FZF_DEFAULT_OPTS='--color=bg+:#293739,bg:#1B1D1E,border:#808080,spinner:#E6DB74,hl:#7E8E91,fg:#F8F8F2,header:#7E8E91,info:#A6E22E,pointer:#A6E22E,marker:#F92672,fg+:#F8F8F2,prompt:#F92672,hl+:#F92672'
    export FZF_DEFAULT_OPTS='--color=bg+:#293739,bg:#1B1D1E,border:#808080,spinner:#E6DB74,hl:#F92672,fg:#F8F8F2,header:#7E8E91,info:#A6E22E,pointer:#A6E22E,marker:#F92672,fg+:#F8F8F2,prompt:#F92672,hl+:#F92672'
    # Auto-completion
    # ---------------
    if [ -d $HOME/.zsh/.fzf/ ]; then
        [[ $- == *i* ]] && source "$HOME/.zsh/.fzf/shell/completion.zsh" 2> /dev/null
        # Key bindings
        source "$HOME/.zsh/.fzf/shell/key-bindings.zsh"
    elif [ -d /opt/homebrew/ ]; then
        WHICH_CMD=$(/bin/bash -c "which which")
        fzf_bin_path=$($WHICH_CMD "fzf")
        fzf_sympath=$(greadlink -f $fzf_bin_path)
        fzf_realpath=$(dirname $(dirname $fzf_sympath))

        [[ $- == *i* ]] && source "$fzf_realpath/shell/completion.zsh" 2> /dev/null
        # Key bindings
        source "$fzf_realpath/shell/key-bindings.zsh"
    fi

    # fzf file search command
    # -----------------------
    if [ "$(command -v fd)" != "" ]; then
        # export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --no-ignore'
        # ignore binary file
        export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --no-ignore -X grep -lI .'
        # .git 디렉토리를 제외하고 검색
        # export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --no-ignore --exclude .git'
        # export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --no-ignore --color=always --exclude .git'
    else
        # export FZF_DEFAULT_COMMAND=''
        # export FZF_DEFAULT_COMMAND='find . -type f'
        # ignore binary file
        export FZF_DEFAULT_COMMAND='find . -type f -exec grep -lI . {} \;'
    fi
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi




# alias file
if ! (declare -f -F "fualias" > /dev/null); then
    if [ -f ~/.aliases ]; then
        . ~/.aliases
    fi
fi

# wgetrc - --no-check-certificate option default
if [ ! -f $HOME/.wgetrc ]; then
    echo "check_certificate = off" >> ~/.wgetrc
fi

if [ -n "$(command -v nvim)" ]; then
    local nvim_tmp=$(nvim -V1 -v | grep "\$VIM:" | awk -F '\\$VIM: ' '{ print $2 }')
    if [ -z "$nvim_tmp" ]; then
        nvim_tmp=$(echo "${nvim_tmp:1:$(expr ${#nvim_tmp} - 2)}")
        if [ -n "$nvim_tmp" ]; then
            export VIMPATH=$nvim_tmp
        fi
    fi
    nvim_tmp=$(echo "${nvim_tmp:1:$(expr ${#nvim_tmp} - 2)}")
    if [ -n "$nvim_tmp" ]; then
        export VIMPATH=$nvim_tmp
    fi
fi

if [ -f "$HOME/.dotfiles/script/iterm/iterm2_shell_integration.zsh" ]; then
    source "$HOME/.dotfiles/script/iterm/iterm2_shell_integration.zsh"
else
    $HOME/.dotfiles/script/iterm/install_shell_integrated.sh
    if [ -f "$HOME/.dotfiles/script/iterm/iterm2_shell_integration.zsh" ]; then
        source "$HOME/.dotfiles/script/iterm/iterm2_shell_integration.zsh"
    fi
fi


# bindkey
if [ -f "$HOME/.dotfiles/bindkey/bindkey.sh" ]; then
    source $HOME/.dotfiles/bindkey/bindkey.sh
fi

# ssh-agent
if [ -f "$HOME/.dotfiles/script/ssh-agent-init.sh" ]; then
    source $HOME/.dotfiles/script/ssh-agent-init.sh
fi



bindkey -M menuselect '^M' .accept-line

setopt menu_complete
# zmodload -i zsh/complist
autoload predict-on
# predict-on
unsetopt menucomplete

export CLICOLOR=1


typeset -g GITSTATUS_NUM_THREADS=8


# ls, fg 및 관련 alias들을 히스토리에서 제외
# typeset -g HISTORY_IGNORE="(ls|ls *|ll|ll *|la|la *|l|l *|lea|lea *|fg|fg *)"

HISTORY_IGNORES=(
    '^l([[:space:]]*)?$'
    '^ls([[:space:]]*)?$'
    '^ll([[:space:]]*)?$'
    '^lea([[:space:]]*)?$'
    '^fg([[:space:]].*)?$'
)

zshaddhistory() {
    emulate -L zsh
    setopt extendedglob

    # [[ $1 != (ls[[:space:]]#|fg[[:space:]]#)$'\n' ]]
    local ls_pattern="ls[[:space:]]#"
    local fg_pattern="fg[[:space:]]#"
    local ignore_pattern="($ls_pattern|$fg_pattern)"

    # 명령어가 패턴과 일치하는지 확인
    # [[ $1 != ${ignore_pattern}$'\n' ]]

    cmd="$1"
    for ignore in "${HISTORY_IGNORES[@]}" ; do
        if [[ "${cmd%$'\n'}" =~ $ignore ]]; then
            return 1
        fi
    done
    return 0
}
