" set shell=C:\Windows\System32\cmd.exe

" hex editor
" :%!xxd
" hex to text editor
" %!xxd -r

set hlsearch
set nu
set rnu
set noic

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


nnoremap <C-Y> <ESC>:e!<CR>G
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

inoremap <C-J> <DOWN>
inoremap <C-K> <UP>
inoremap <C-L> <RIGHT>
inoremap <C-H> <LEFT>
inoremap <C-N> <BS>
"inoremap <C-F> <C-P>
xnoremap <C-J> <DOWN>
xnoremap <C-K> <UP>
xnoremap <C-L> <RIGHT>
xnoremap <C-H> <LEFT>
xnoremap <C-N> <BS>
snoremap <C-J> <DOWN>
snoremap <C-K> <UP>
snoremap <C-L> <RIGHT>
snoremap <C-H> <LEFT>
snoremap <C-N> <BS>
onoremap <C-J> <DOWN>
onoremap <C-K> <UP>
onoremap <C-L> <RIGHT>
onoremap <C-H> <LEFT>
onoremap <C-N> <BS>
cnoremap <C-J> <DOWN>
cnoremap <C-K> <UP>
cnoremap <C-L> <RIGHT>
cnoremap <C-H> <LEFT>
cnoremap <C-N> <BS>

nnoremap ; :
vnoremap ; :



nnoremap - ^
vnoremap - ^
" noremap - <nop>
" nnoremap r R

noremap _ <c-x>
noremap + <c-a>


" 오름차순 1,2,3,4,5
" nnoremap <C-M> <C-e>
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
nnoremap f <C-W><C-W>
nnoremap F <C-W><C-W>
" nnoremap <c-f> <C-W><C-W>

" nnoremap <Leader>g <C-W>-
" vnoremap <Leader>g <C-W>-
" nnoremap <Leader>h <C-W>+
" vnoremap <Leader>h <C-W>+
nnoremap <Leader>r <C-W>-
vnoremap <Leader>r <C-W>-
nnoremap <Leader>t <C-W>+
vnoremap <Leader>t <C-W>+
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

nnoremap <C-D> 15<C-E>
nnoremap <C-A> 15<C-Y>
vnoremap <C-D> 15<C-E>j
vnoremap <C-A> 15<C-Y>k

nnoremap <Leader>a <C-U>
nnoremap <Leader>d <C-D>
vnoremap <Leader>a <C-U>
vnoremap <Leader>d <C-D>


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
" nnoremap H <C-W><C-H>
" nnoremap J <C-W><C-J>
" nnoremap K <C-W><C-K>
" nnoremap L <C-W><C-L>

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
" nnoremap ! ^
" vnoremap ! ^
nnoremap ' <ESC>:noh<CR> /\|\|\|########@@@@@@@@ vim_search_init @@@@@@@@########\|\|\|; <CR>zz
vnoremap ' <ESC>:noh<CR> /\|\|\|########@@@@@@@@ vim_search_init @@@@@@@@########\|\|\|; <CR>zz
" nnoremap ' <ESC>:noh<CR>
" vnoremap ' <ESC>:noh<CR>
nnoremap & '
vnoremap & '
noremap <c-]> q


