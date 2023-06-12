if !empty(glob($HOME."/.dotfiles/vimrc/.vs.vimrc"))
	source $HOME/.dotfiles/vimrc/.vs.vimrc
endif

if !empty(glob($HOME."/.dotfiles/vimrc/.li.vimrc"))
	source $HOME/.dotfiles/vimrc/.li.vimrc
endif

" /Applications/MacVim.app/Contents/Resources/vim/gvimrc
if has("gui_macvim")
	source $HOME/.dotfiles/vimrc/.mac.vimrc
endif

" if !empty(glob($HOME."/.dotfiles/.neo.vimrc"))
" 	source $HOME/.dotfiles/.neo.vimrc
" endif

if isdirectory("/opt/homebrew/")
	set clipboard=unnamed
endif
