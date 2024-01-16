" ===== man page 설정 =====

" 파일 인코딩을 한국어로
if $LANG[0]=='k' && $LANG[1]=='o'
    set fileencoding=korea
endif

syntax enable
" 구문 강조 사용
if has("syntax")
    syntax on
endif



" RealVim realvim
ca w!! w !sudo tee "%" > /dev/null


let g:open_path = getcwd()

if isdirectory($HOME."/.vim/pack/autopair") || isdirectory($HOME."/.vim/plugged/autopair")
    " Autopair Disable
    let g:AutoPairsLoaded = 0
endif

if isdirectory($HOME."/.vim/pack/airline") || isdirectory($HOME."/.vim/plugged/vim-airline")
    " 버퍼 목록 켜기
    let g:airline#extensions#tabline#enabled = 1
    " 파일명만 출력
    let g:airline#extensions#tabline#fnamemod = ':t'
    " powerline 폰트가 없는 경우 아래를 uncomment
    " let g:airline#extensions#tabline#left_sep = ' '
    " let g:airline#extensions#tabline#left_alt_sep = '|'

    let g:airline_theme='luna'
    let g:airline_powerline_fonts = 1
    let g:svnj_warn_branch_log=0
    "let g:airline_highlighting_cache=1

    " Airline BufExp
    let g:miniBufExplMapWindowNavVim = 1
    let g:miniBufExplMapWindowNavArrows = 1
    let g:miniBufExplMapCTabSwitchBufs = 1
    let g:miniBufExplModSelTarget = 1
endif

if !isdirectory($HOME."/.vim/plugged/vim-surround")
	noremap S s
endif

nnoremap <c-l> :suspend<CR>
noremap . <Plug>Sneak_s

set shell=/bin/bash

set laststatus=2    "항상 파일명 표시
set nobackup        "백업파일 만들지 않는다.
set ts=4            "탭을 4칸으로
set sw=4
set sts=4
set smartcase
set smarttab
set foldmethod=manual
set foldopen-=hor
set foldopen-=undo
set foldopen-=search
set diffopt=filler,foldcolumn:0
set noea
set wildmenu
set fileencodings=utf-8,cp949,euc-kr
set encoding=utf-8
set lazyredraw
set ruler
set showmatch
set showmode
set notitle
" set csprg=/usr/bin/cscope
" set csto=0
" only vim

if !has("nvim")
    set cst
    set nocsverb
endif

" split
set splitbelow
set splitright

set incsearch
set magic

set nofixeol
set nofixendofline
set noeol

set previewheight=16
set pastetoggle=<c-n><c-p>

if ! exists("*stdpath")
    set term=xterm-256color
    set t_Co=256
endif
if $TERM == 'xterm-256color'
nnoremap <esc>^[ <esc>^[
endif

function! InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col-1]!~'\k'
        return "\<TAB>"
    else
        if pumvisible()
            return "\<C-N>"
        else
            return "\<C-N>\<C-P>"
        end
    endif
endfunction

function! InsertSTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col-1]!~'\k'
        return "\<TAB>"
    else
        if pumvisible()
            return "\<C-P>"
        else
            return "\<C-P>\<C-N>"
        end
    endif
endfunction

inoremap <tab> <c-r>=InsertTabWrapper()<cr>
inoremap <s-tab> <c-r>=InsertSTabWrapper()<cr>
" Acp
if (!empty(glob($HOME."/.vim/plugin/acp.vim"))) || isdirectory($HOME."/.vim/plugged/AutoComplPop")
    let g:acp_enableAtStartup = 1
    let g:acp_mappingDriven = 0
    let g:acp_completeOption = '.,w,b,u,i'
    set complete-=t
    let g:acp_behaviorKeywordLength = 3
    let g:acp_behaviorRubyOmniMethodLength = -1
    let g:acp_behaviorPythonOmniLength = -1
    let g:acp_behaviorPerlOmniLength = -1
    let g:acp_behaviorXmlOmniLength = -1
    let g:acp_behaviorHtmlOmniLength = -1
    let g:acp_behaviorCssOmniPropertyLength = -1
    let g:acp_behaviorCssOmniPropertyLength = -1
    let g:acp_behaviorCssOmniValueLength = -1
endif
" EasyMotion
if (!empty(glob($HOME."/.vim/pack/easymotion"))) || isdirectory($HOME."/.vim/plugged/vim-easymotion")
    let g:EasyMotion_smartcase = 0
    let g:EasyMotion_use_smartsign_us = 0
    nnoremap s <Plug>(easymotion-s2)
endif


" Find Word
" 오름차순 1,2,3,4,5
func! N_find_word_asc()
    let l:toplinenum=winsaveview().topline
    call feedkeys("*N\<ESC>:call winrestview({'topline' : ".l:toplinenum."})\<CR>:\<BS>", 'n')
    let @/ = '\<'.expand('<cword>').'\>'
endfunc

" 내림차순 5,4,3,2,1
func! N_find_word_desc()
    let l:toplinenum=winsaveview().topline
    call feedkeys("#N\<ESC>:call winrestview({'topline' : ".l:toplinenum."})\<CR>:\<BS>", 'n')
    let @/ = '\<'.expand('<cword>').'\>'
endfunc

func! V_find_word_asc()
    let l:toplinenum=winsaveview().topline
    vnoremap # y/<c-r>"<CR>N
    call feedkeys("\<ESC>:call winrestview({'topline' : ".l:toplinenum."})\<CR>:\<BS>", 'n')
endfunc

nnoremap <silent> # <ESC>:call N_find_word_asc()<CR>
vnoremap <silent> # <ESC>:call V_find_word_asc()<CR>
nnoremap <silent> * <ESC>:call N_find_word_desc()<CR>
nnoremap F <ESC>:call Prev_window()<CR>
func! Prev_window()
    let l:curnr=winnr()
    if l:curnr==1
        let l:curnr=winnr('$')
    else
        let l:curnr=l:curnr-1
    endif
    execute l:curnr." wincmd w"
endfunc


" get SynColor(SynGroup) in cursor
" call SynStack() or call SynGroup()
function! SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

function! SynGroup()
    let l:s = synID(line('.'), col('.'), 1)
    echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
endfun


set bg=dark
if isdirectory($HOME."/.vim/plugged/vim-github-theme")
    colorscheme github_dark
    " colorscheme default
else
    colorscheme default
endif


hi! Search term=reverse cterm=NONE ctermfg=0 ctermbg=184 gui=NONE guifg=#000000 guibg=#d7d700
highlight! StatusLine ctermfg=231 ctermbg=23 guifg=#ffffff guibg=#002b2b cterm=NONE
highlight! WildMenu ctermfg=0 ctermbg=36 guifg=#ffffff guibg=#005252
hi Pmenu ctermbg=yellow ctermfg=black guibg=yellow guifg=black
hi PmenuSel ctermbg=darkgrey ctermfg=lightgrey guibg=darkgrey ctermfg=lightgrey
hi PmenuSbar ctermbg=grey guibg=grey

if g:colors_name == 'default'
    hi! comment ctermfg=72
endif

" highlight link EchoDocPopup Pmenu

func! WinEnterFunction()
    silent! execute 'cd' expand('%:p:h')
endfunc

if has("autocmd")
    au BufWinEnter,WinEnter * call WinEnterFunction()
endif


