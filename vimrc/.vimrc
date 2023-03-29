if !empty(glob($HOME."/dotfiles/vimrc/.vsvimrc"))
	source $HOME/dotfiles/vimrc/.vsvimrc
endif

if !empty(glob($HOME."/dotfiles/vimrc/.livimrc"))
	source $HOME/dotfiles/vimrc/.livimrc
endif

if has ("gui_macvim")
	source $HOME/dotfiles/vimrc/.macvimrc
endif

" if !empty(glob($HOME."/dotfiles/.neovimrc"))
" 	source $HOME/dotfiles/.neovimrc
" endif

if isdirectory("/opt/homebrew/")
	set clipboard=unnamed
endif
