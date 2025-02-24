" hex editor
" :%!xxd
" hex to text editor
" %!xxd -r

set matchpairs=(:),{:},[:],<:>

set hlsearch
set nu
set rnu
set noic
set scrolloff=5

noremap q <nop>
nnoremap Q <nop>
let mapleader='s'
noremap \ <nop>
" map S s


"nnoremap o $a<CR>

cnoreabbrev ss sh

" delete not copy
nnoremap x "_x
vnoremap x "_x
vnoremap X "_x
" vnoremap d "_d
" vnoremap D "_d
" noremap DL "_x
" noremap DH "_X
" nnoremap x "_x
noremap D "_d
nnoremap DD "_dd
nnoremap DW "_dw
nnoremap D@ "_d^
nnoremap D) "_d0

" nnoremap <Leader>q <ESC>:set nu!<CR>
" nnoremap <Leader>w <ESC>:set rnu!<CR>
nnoremap <Leader>y g~w

" set wrap
noremap j gj
noremap k gk


nnoremap <C-y> <ESC>:e!<CR>G
nnoremap Q @

"fold key
nnoremap ,a zf
vnoremap ,a zf
" nnoremap <leader>f zf
" vnoremap <leader>f zf
noremap ,f za
noremap ,o zo
noremap ,d zd
" noremap ,o zA
" nnoremap <Leader>o zA
" vnoremap <Leader>o zA
nnoremap ,u zd
vnoremap ,u zd
nnoremap ,U zD
vnoremap ,U zD

noremap za zf
noremap zf za
noremap zk za
noremap zi za
" nnoremap <Leader>e zd
" vnoremap <Leader>e zd
" nnoremap <Leader>E zD
" vnoremap <Leader>E zD
nnoremap ,q v]}zf
vnoremap ,q v]}zf
nnoremap ,w v}zf
vnoremap ,w v}zf


" C-Space in Windows or GVim

noremap <Space> <nop>
noremap q <nop>
" nnoremap <C-space> <ESC>
" inoremap <C-space> <ESC>
" vnoremap <C-space> <ESC>
" snoremap <C-space> <ESC>
" onoremap <C-space> <ESC>
" xnoremap <C-space> <ESC>
" lnoremap <C-space> <ESC>
" cnoremap <C-space> <C-C>

inoremap <C-j> <DOWN>
inoremap <C-k> <UP>
inoremap <C-l> <RIGHT>
inoremap <C-h> <LEFT>
" inoremap <C-n> <BS>
"inoremap <C-f> <C-P>
xnoremap <C-j> <DOWN>
xnoremap <C-k> <UP>
xnoremap <C-l> <RIGHT>
xnoremap <C-h> <LEFT>
" xnoremap <C-n> <BS>
snoremap <C-j> <DOWN>
snoremap <C-k> <UP>
snoremap <C-l> <RIGHT>
snoremap <C-h> <LEFT>
" snoremap <C-n> <BS>
onoremap <C-j> <DOWN>
onoremap <C-k> <UP>
onoremap <C-l> <RIGHT>
onoremap <C-h> <LEFT>
" onoremap <C-n> <BS>
cnoremap <C-j> <DOWN>
cnoremap <C-k> <UP>
cnoremap <C-l> <RIGHT>
cnoremap <C-h> <LEFT>
cnoremap <C-o> <C-n>
" cnoremap <C-n> <BS>

nnoremap ; :
vnoremap ; :



nnoremap - ^
vnoremap - ^
" noremap - <nop>
" nnoremap r R

noremap _ <C-x>
noremap + <C-a>


" 오름차순 1,2,3,4,5
" nnoremap <C-m> <C-e>
" nnoremap , ;
" nnoremap . ;
nnoremap ye <ESC>hebye<ESC>
nnoremap yq <ESC>ggyG<C-o>zz<ESC>
nnoremap # <ESC>:set hlsearch<CR>#Nzz*Nzzvey
nnoremap * <ESC>:set hlsearch<CR>#Nzzvey
" nnoremap <Space> <ESC>:set hlsearch<CR>#Nzz*Nzz
nnoremap <S-A> <ESC>:set hlsearch<CR>#Nzz*Nzz
nnoremap <S-I> <ESC>:set hlsearch<CR>#Nzz
" nnoremap n nzz
" nnoremap N Nzz
vnoremap # y/<c-r>"<CR>Nzz
vnoremap * y?<c-r>"<CR>Nzz

nnoremap t ge
nnoremap T gE
vnoremap t ge
vnoremap T gE
nnoremap f <C-w><C-w>
nnoremap F <C-w><C-w>
" nnoremap <c-f> <C-w><C-w>

" nnoremap <Leader>g <C-w>-
" vnoremap <Leader>g <C-w>-
" nnoremap <Leader>h <C-w>+
" vnoremap <Leader>h <C-w>+
nnoremap <Leader>r <C-w>-
vnoremap <Leader>r <C-w>-
nnoremap <Leader>t <C-w>+
vnoremap <Leader>t <C-w>+
nnoremap <Leader>, <C-w><
vnoremap <Leader>, <C-w><
nnoremap <Leader>. <C-w>>
vnoremap <Leader>. <C-w>>
nnoremap <Leader>v <C-W>=
vnoremap <Leader>v <C-W>=
nnoremap <Leader>r <c-w>K
nnoremap <Leader>t <c-w>H
nnoremap <Leader>p <ESC>:sp<CR>

nnoremap <Leader>u :bp<CR>
nnoremap <Leader>i :bn<CR>

nnoremap <C-d> 15<C-e>
nnoremap <C-a> 15<C-y>
vnoremap <C-d> 15<C-e>j
vnoremap <C-a> 15<C-y>k

nnoremap <C-g> <C-f>
nnoremap <C-f> <C-y>
vnoremap <C-f> <C-y>
nnoremap <C-a> <C-u>
nnoremap <silent><C-u> <ESC><C-]>
vnoremap q ge
vnoremap Q gE
nnoremap @ %
vnoremap @ %
nnoremap % ^
vnoremap % ^
nmap <Tab>q ^
nnoremap <Tab>w %
nnoremap <Tab>e $
nmap <Tab>r 0
nmap <Tab>3 $h
vmap <Tab>q ^
vnoremap <Tab>w %
vnoremap <Tab>e $
vmap <Tab>r 0
vmap <Tab>3 $h

noremap <C-x> <nop>

" nnoremap <Leader>a <C-u>
" nnoremap <Leader>d <C-d>
" vnoremap <Leader>a <C-u>
" vnoremap <Leader>d <C-d>


nnoremap <C-k> H
nnoremap <C-j> L
nnoremap <C-h> M
" nnoremap <c-l> :suspend<CR>


nnoremap U K
nnoremap L <nop>
nnoremap H <nop>
nnoremap M J
" noremap <S-k> {
" noremap <S-j> }
noremap <S-h> ^
noremap <S-l> $
" nnoremap H M
" nnoremap K H
" nnoremap J L
" nnoremap H <C-w><C-h>
" nnoremap J <C-w><C-j>
" nnoremap K <C-w><C-k>
" nnoremap L <C-w><C-l>

" inoremap <c-a> <ESC>^i
" inoremap <c-d> <ESC>$a
" VSCODEVIM 지원 안함
" inoremap <c-a> <HOME>
" inoremap <c-d> <End>
inoremap <C-w> <ESC><right>wi
inoremap <C-b> <ESC>bi
inoremap <C-e> <ESC><right>ea
inoremap <C-t> <ESC>gei
inoremap <C-f> <ESC><c-e>a
inoremap <C-y> <ESC><c-y>a
inoremap <C-p> <ESC>pa
inoremap <C-p> <ESC>pa
inoremap <C-o> <ESC>o
inoremap <C-i> <ESC>O
inoremap <C-x> <Del>
inoremap <C-c> <BS>
inoremap <Tab> <Tab>


" bookmark
noremap <S-q> %
nnoremap ^ `
vnoremap ^ `
noremap ` m
vnoremap $ $h
nnoremap ' <ESC>:noh<CR> /\|\|\|########@@@@@@@@ vim_search_init @@@@@@@@########\|\|\|; <CR>zz
vnoremap ' <ESC>:noh<CR> /\|\|\|########@@@@@@@@ vim_search_init @@@@@@@@########\|\|\|; <CR>zz
" nnoremap ' <ESC>:noh<CR>
" vnoremap ' <ESC>:noh<CR>
nnoremap & '
vnoremap & '
noremap <C-]> q


