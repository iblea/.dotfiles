
if g:color_name == 'monokai'
    " colorscheme monokai
    hi Normal ctermfg=231 guifg=#f8f8f2
endif


hi! Search term=reverse
" hi! Normal cterm=NONE ctermfg=0 ctermbg=184 gui=NONE guifg=#000000 guibg=#d7d700
" Make the background transparent
" hi Normal cleared
" hi Normal ctermfg=252 ctermbg=NONE guifg=#C9D1D9 guibg=#0D1117
hi Normal ctermfg=252 ctermbg=NONE guifg=#C9D1D9 guibg=#000000
hi clear LineNr 
" hi LineNr guibg=NONE ctermbg=NONE

highlight! StatusLine ctermfg=231 ctermbg=23 guifg=#ffffff guibg=#002b2b cterm=NONE
highlight! WildMenu ctermfg=0 ctermbg=36 guifg=#ffffff guibg=#005252
hi Pmenu ctermbg=yellow ctermfg=black guibg=yellow guifg=black
hi PmenuSel ctermbg=darkgrey ctermfg=lightgrey guibg=darkgrey ctermfg=lightgrey
hi PmenuSbar ctermbg=grey guibg=grey
hi Search ctermfg=0 ctermbg=184 guifg=Black guibg=Yellow

if g:colors_name == 'default'
    hi! comment ctermfg=72
endif

