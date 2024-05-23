
" vim script lua embedded highlight
autocmd FileType vim lua vim.treesitter.start()
lua << EOF
vim.g.ts_highlight_lua = true
EOF
let g:vimsyn_embed = 'lPr'  " support embedded lua, python and ruby

" 구문 강조 사용
if has("syntax")
    syntax on
endif

set directory=.

lua << EOF
package.path = package.path .. ';' .. os.getenv("HOME") .. '/.dotfiles/vimrc/neovim/?.lua'
require('luainit')
EOF


if !empty(glob($HOME."/.dotfiles/vimrc/.vs.vimrc"))
	source $HOME/.dotfiles/vimrc/.vs.vimrc
endif

if has("gui_running")
	source $HOME/.dotfiles/vimrc/gui.vimrc
	" lua require("gui_init")
	" set columns=120
	set sessionoptions+=winsize,winpos
endif

if isdirectory("/opt/homebrew/")
	set clipboard=unnamed
endif


function! Get_visual_selection()
    " Why is this not a built-in Vim script function?!
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]
    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][col1 - 1:]
    return join(lines, "\n")
endfunction

" Find Word
" 오름차순 1,2,3,4,5
func! N_find_word_asc()
    let l:toplinenum=winsaveview().topline
    call feedkeys("*N\<ESC>:call winrestview({'topline' : ".l:toplinenum."})\<CR>:\<BS>", 'n')
    if has("clipboard")
        let @+ = expand('<cword>')
    endif
    let @" = expand('<cword>')
    let @/ = '\<'.expand('<cword>').'\>'
endfunc

" 내림차순 5,4,3,2,1
func! N_find_word_desc()
    let l:toplinenum=winsaveview().topline
    call feedkeys("#N\<ESC>:call winrestview({'topline' : ".l:toplinenum."})\<CR>:\<BS>", 'n')
    if has("clipboard")
        let @+ = expand('<cword>')
    endif
    let @" = expand('<cword>')
    let @/ = '\<'.expand('<cword>').'\>'
endfunc

func! V_find_word_asc()
    let l:newWord = Get_visual_selection()
    if has("nvim")
        let @+ = expand('<cword>')
    endif
    let l:newWord = substitute(l:newWord, "\\", "\\\\\\\\", "g")
    let @/ = l:newWord
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
function! SynStackVim()
    if !exists("*synstack")
        return
    endif
    echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

function! SynGroupVim()
    let l:s = synID(line('.'), col('.'), 1)
    echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
endfun

func! WinEnterFunction()
    silent! execute 'cd' expand('%:p:h')
endfunc

if has("autocmd")
    au BufWinEnter,WinEnter * call WinEnterFunction()
	autocmd TermOpen * startinsert
endif
