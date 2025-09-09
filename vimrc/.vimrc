
" ${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/"

if !empty(glob($HOME."/.vim/autoload/plug.vim"))
	call plug#begin($HOME.'/.vim/plugged')

	Plug 'preservim/nerdtree'
	" Plug 'vim-scripts/AutoComplPop'
	Plug 'iblea/AutoComplPop'

	" if version >= 900
	" Plug 'girishji/vimcomplete'
	" Plug 'github/copilot.vim'
	" endif
	
	" Plug 'lifepillar/vim-mucomplete'
	Plug 'vim-airline/vim-airline'
	Plug 'vim-airline/vim-airline-themes'
	Plug 'jlanzarotta/bufexplorer'
	Plug 'vim-scripts/BufOnly.vim'
	Plug 'kien/ctrlp.vim'
	Plug 'wincent/ferret'
	Plug 'easymotion/vim-easymotion'
	Plug 'preservim/vim-indent-guides'
	Plug 'mtth/scratch.vim'
	Plug 'tpope/vim-surround'
	Plug 'justinmk/vim-sneak'
	Plug 'vim-scripts/TagHighlight'
	Plug 'vim-scripts/EasyColour'

	Plug  'powerman/vim-plugin-AnsiEsc'

	" Monokai
	Plug 'ku1ik/vim-monokai'

	" Plug 'akiicat/vim-github-theme'
	Plug 'iblea/vim-github-theme'
	" only use neovim
	" Plug 'projekt0n/github-nvim-theme'

	call plug#end()
endif

if !empty(glob($HOME."/.dotfiles/vimrc/.vs.vimrc"))
	source $HOME/.dotfiles/vimrc/.vs.vimrc
endif

if !empty(glob($HOME."/.dotfiles/vimrc/.li.vimrc"))
	source $HOME/.dotfiles/vimrc/.li.vimrc
endif

" /Applications/MacVim.app/Contents/Resources/vim/gvimrc
" if has("gui_macvim")
" 	source $HOME/.dotfiles/vimrc/gui.vimrc
" endif

" if has("nvim")
" 	if !empty(glob($HOME."/.dotfiles/.neo.vimrc"))
" 		source $HOME/.dotfiles/vimrc/neovim/neovim.vimrc
" 		lua require
" 	endif
"
" 	if has("gui_running")
" 		source $HOME/.dotfiles/vimrc/gui.vimrc
" 	endif
" endif

if isdirectory("/opt/homebrew/")
	set clipboard=unnamed
endif

