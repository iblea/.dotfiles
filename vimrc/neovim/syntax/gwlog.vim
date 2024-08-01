syntax match GwDate /^[0-9][0-9]\/[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]/
syntax match GwFunction /| [a-zA-Z0-9_]*:/
" syntax match GwFunction /(:| )?[a-zA-Z0-9_]*:/
syntax match GwLevelINF /| INF:[a-zA-Z0-9_]*:/
syntax match GwLevelERR /| ERR:[a-zA-Z0-9_]*:/
syntax match GwTcpLog / syn [0-9]* fin [0-9-]* ack [0-9-]* rst [0-9-]* urg [0-9-]*/
syntax match GwFDLog0 / FD -[0-9]*/
syntax match GwFDLog1 / FD [0-9]*[13579]\{1\}[ ,.]\{1\}/
syntax match GwFDLog2 / FD [0-9]*[02468]\{1\}[ ,.]\{1\}/
syntax match GwFDLog3 / FD [0-9]*[13579]\{1\}$/
syntax match GwFDLog4 / FD [0-9]*[02468]\{1\}$/

" syntax match GwFDLog0 / FD -[0-9]* /
" syntax match GwFDLog0 / FD -[0-9]*,/
" syntax match GwFDLog0 / FD -[0-9]*$/
" syntax match GwFDLog1 / FD [0-9]*[13579]\{1\} /
" syntax match GwFDLog1 / FD [0-9]*[13579]\{1\},/
" syntax match GwFDLog1 / FD [0-9]*[13579]\{1\}$/
" syntax match GwFDLog2 / FD [0-9]*[02468]\{1\} /
" syntax match GwFDLog2 / FD [0-9]*[02468]\{1\},/
" syntax match GwFDLog2 / FD [0-9]*[02468]\{1\}$/
syntax match GwIPLog  / src [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}, dest [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$/
syntax match GwPortLog  / src [0-9]\{1,5\}, dst [0-9]\{1,5\}$/
syntax match GwIncomingLog  / incomming seq -\?[0-9]*, ack -\?[0-9]*, wnd -\?[0-9]*$/
syntax match GwOutgoingLog  / outgoing seq -\?[0-9]*, ack -\?[0-9]*, wnd -\?[0-9]*$/

" highlight GwDate   ctermfg=cyan guifg=#00ffff
" highlight GwLevelINF  ctermfg=yellow guifg=#ffff00
" highlight GwLevelERR  ctermfg=red  guifg=#ff0000
" highlight GwFunction  ctermfg=112  guifg=#87d700
highlight GwDate   ctermfg=cyan guifg=#63d4ea
highlight GwLevelINF  ctermfg=yellow guifg=#ffd866
highlight GwLevelERR  ctermfg=red  guifg=#f82a71
highlight GwFunction  ctermfg=41  guifg=#a6e12e

highlight GwTcpLog   ctermfg=141 guifg=#af87ff
highlight GwFDLog0   ctermfg=93 guifg=#8700ff
highlight GwFDLog1   ctermfg=201 guifg=#ff00ff
" highlight GwFDLog1   ctermfg=207 guifg=#ff5fff
highlight GwFDLog2   ctermfg=213 guifg=#ff87ff
highlight GwFDLog3   ctermfg=201 guifg=#ff00ff
" highlight GwFDLog3   ctermfg=207 guifg=#ff5fff
highlight GwFDLog4   ctermfg=213 guifg=#ff87ff
highlight GwIPLog    ctermfg=86  guifg=#5fffd7
highlight GwPortLog    ctermfg=159  guifg=#afffff
highlight GwIncomingLog    ctermfg=76  guifg=#5fd700
highlight GwOutgoingLog    ctermfg=36  guifg=#00af87


let b:current_syntax = 'gwlog'
