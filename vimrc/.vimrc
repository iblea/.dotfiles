
" ${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/"

if !empty(glob($HOME."/.vim/autoload/plug.vim"))
	call plug#begin($HOME.'/.vim/plugged')

	Plug 'preservim/nerdtree'
	Plug 'vim-scripts/AutoComplPop'
	Plug 'vim-airline/vim-airline'
	Plug 'vim-airline/vim-airline-themes'
	Plug 'jlanzarotta/bufexplorer'
	Plug 'vim-scripts/BufOnly.vim'
	Plug 'kien/ctrlp.vim'
	Plug 'wincent/ferret'
	Plug 'github/copilot.vim'
	Plug 'easymotion/vim-easymotion'
	Plug 'preservim/vim-indent-guides'
	Plug 'mtth/scratch.vim'
	Plug 'tpope/vim-surround'
	Plug 'justinmk/vim-sneak'
	Plug 'vim-scripts/TagHighlight'
	Plug 'vim-scripts/EasyColour'
	
	" Plug 'akiicat/vim-github-theme'
	Plug 'jdh9232/vim-github-theme'
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
if has("gui_macvim")
	source $HOME/.dotfiles/vimrc/.mac.vimrc
endif

if has("nvim")
	if !empty(glob($HOME."/.dotfiles/.neo.vimrc"))
		source $HOME/.dotfiles/.neo.vimrc
	endif
endif

if isdirectory("/opt/homebrew/")
	set clipboard=unnamed
endif
