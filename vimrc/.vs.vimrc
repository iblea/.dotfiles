" set shell=C:\Windows\System32\cmd.exe

" hex editor
" :%!xxd
" hex to text editor
" %!xxd -r

set hlsearch
set nu
set rnu
set noic
set scrolloff=5

noremap s <nop>
noremap S <nop>
let mapleader='q'
noremap \ <nop>
map S s


"nnoremap o $a<CR>

cnoreabbrev ss sh

" delete not copy
vnoremap x "_x
vnoremap X "_x
" vnoremap d "_d
" vnoremap D "_d
" noremap DL "_x
" noremap DH "_X
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
nnoremap ,f zf
vnoremap ,f zf
" nnoremap <leader>f zf
" vnoremap <leader>f zf
nnoremap ,i za
vnoremap ,i za
nnoremap ,o zA
vnoremap ,o zA
" nnoremap <Leader>o zA
" vnoremap <Leader>o zA
nnoremap ,u zd
vnoremap ,u zd
nnoremap ,U zD
vnoremap ,U zD
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
inoremap <C-n> <BS>
"inoremap <C-f> <C-P>
xnoremap <C-j> <DOWN>
xnoremap <C-k> <UP>
xnoremap <C-l> <RIGHT>
xnoremap <C-h> <LEFT>
xnoremap <C-n> <BS>
snoremap <C-j> <DOWN>
snoremap <C-k> <UP>
snoremap <C-l> <RIGHT>
snoremap <C-h> <LEFT>
snoremap <C-n> <BS>
onoremap <C-j> <DOWN>
onoremap <C-k> <UP>
onoremap <C-l> <RIGHT>
onoremap <C-h> <LEFT>
onoremap <C-n> <BS>
cnoremap <C-j> <DOWN>
cnoremap <C-k> <UP>
cnoremap <C-l> <RIGHT>
cnoremap <C-h> <LEFT>
cnoremap <C-n> <BS>

nnoremap ; :
vnoremap ; :



nnoremap - ^
vnoremap - ^
" noremap - <nop>
" nnoremap r R

noremap _ <c-x>
noremap + <c-a>


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
" nnoremap <Leader>r <c-w>K
" nnoremap <Leader>t <c-w>H
" nnoremap <Leader>p <ESC>:sp<CR>

" nnoremap <Leader>u :bp<CR>
" nnoremap <Leader>i :bn<CR>


nnoremap <c-g> <c-f>
nnoremap <c-f> <c-y>
vnoremap <c-f> <c-y>
nnoremap <c-a> <c-u>
nnoremap <silent><c-u> <ESC><C-]>
vnoremap q ge
vnoremap Q gE
nmap <Tab>q ^
nmap <Tab>w %
nmap <Tab>e $
nmap <Tab>r 0
nmap <Tab>3 $h
vmap <Tab>q ^
vmap <Tab>w %
vmap <Tab>e $
vmap <Tab>r 0
vmap <Tab>3 $h

nnoremap <C-d> 15<C-e>
nnoremap <C-a> 15<C-y>
vnoremap <C-d> 15<C-e>j
vnoremap <C-a> 15<C-y>k

noremap <C-x> <nop>

nnoremap <Leader>a <C-u>
nnoremap <Leader>d <C-d>
vnoremap <Leader>a <C-u>
vnoremap <Leader>d <C-d>


nnoremap <c-k> H
nnoremap <c-j> L
nnoremap <c-h> M
" nnoremap <c-l> :suspend<CR>


nnoremap U K
nnoremap L <nop>
nnoremap H <nop>
nnoremap M J
noremap <s-k> {
noremap <s-j> }
noremap <s-h> ^
noremap <s-l> $
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
inoremap <c-w> <ESC><right>wi
inoremap <c-b> <ESC>bi
inoremap <c-f> <Del>
inoremap <c-c> <ESC><c-e>a
inoremap <c-x> <ESC><c-y>a
inoremap <c-p> <ESC>pa
inoremap <c-p> <ESC>pa
inoremap <C-o> <ESC>o
inoremap <c-i> <ESC>O


" bookmark
nnoremap ^ `
vnoremap ^ `
noremap ` m
nnoremap @ ^
vnoremap @ ^
nnoremap ' <ESC>:noh<CR> /\|\|\|########@@@@@@@@ vim_search_init @@@@@@@@########\|\|\|; <CR>zz
vnoremap ' <ESC>:noh<CR> /\|\|\|########@@@@@@@@ vim_search_init @@@@@@@@########\|\|\|; <CR>zz
" nnoremap ' <ESC>:noh<CR>
" vnoremap ' <ESC>:noh<CR>
nnoremap & '
vnoremap & '
noremap <c-]> q


