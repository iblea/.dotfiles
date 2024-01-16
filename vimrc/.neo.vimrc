" neovim $MYVIMRC init script (in Windows)
" " input ~\AppData\Local\nvim\
"
" "set runtimepath+=~\Downloads\vimsetjdh\.vim,~\Downloads\vimsetjdh\.vim\after
" set runtimepath+=~\.vim,~\.vim\after
" "set packpath+=~\Downloads\vimsetjdh\.vim
" set packpath+=~\.vim
" source ~\.nvimrc
"
" if has("gui_running")
"     nnoremap <C-Space> <ESC>
"     inoremap <C-Space> <Esc>
" else
" endif



" nvim command neovim nvimrc   (:e $MYVIMRC)
if has("gui_running")
    set clipboard^=unnamed,unnamedplus
    hi! Normal guibg=black guifg=#BBBBBB
    set mouse-=a
    cnoremap <C-Y> <C-V>
    cnoremap <C-V> <nop>
    " silent! set guifont=FantasqueSansMono\ NFM:h12:cDEFAULT
    " silent! set guifontwide=D2Coding:h12:cDEFAULT
    " au VimEnter * execute "GuiFont! FantasqueSansMono Nerd Font Mono:h12"
    au VimEnter * execute "GuiFont! WindowsCommandPrompt Nerd Font:h12"

    if has('win64')
        let &shell='bash.exe'
        let &shellcmdflag = '-c'
    endif
    " let g:python3_host_prog='C:\Python38\python.exe'
    " silent execute 'cd '.$HOME
endif
