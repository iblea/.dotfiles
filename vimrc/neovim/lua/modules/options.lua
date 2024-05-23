local indent = 4 -- num of spaces for indentation
local et_stat = false

-- vim.opt.shell=/bin/zsh

vim.opt.background = "dark"
vim.opt.autoindent = true -- auto indent when starting a new line
vim.opt.breakindent = true -- wrapped line is visually indented
vim.opt.clipboard = "unnamed,unnamedplus"

vim.opt.laststatus=2
vim.opt.backup = false

vim.opt.tabstop = indent
vim.opt.shiftwidth = indent
vim.opt.softtabstop = indent
vim.opt.smartcase = true
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.expandtab = et_stat

local custom_setlocal_stat = true



vim.opt.foldmethod = "manual"
vim.opt.foldopen:remove("hor")
vim.opt.foldopen:remove("undo")
vim.opt.foldopen:remove("search")
-- vim.opt.foldopen -= "hor"
-- vim.opt.foldopen -= "undo"
-- vim.opt.foldopen -= "search"

vim.opt.diffopt = "filler,foldcolumn:0"

vim.opt.equalalways = false
vim.opt.wildmenu = true

vim.opt.fileencodings = "utf-8,euc-kr,cp949,ucs-bom,default,latin1"
-- vim.opt.fileencoding = "utf-8"
vim.opt.encoding = "utf-8"

vim.opt.lazyredraw = true
vim.opt.ruler = true
vim.opt.showmatch = true
vim.opt.showmode = true
vim.opt.title = false

-- set cst
-- set nocsverb

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.incsearch = true
vim.opt.magic = true

vim.opt.fixeol = false
vim.opt.fixendofline = false
vim.opt.eol = false

-- local lang_env = vim.api.nvim_command('echo $LANG')
-- if lang_env[0] == 'k' && lang_env[1] == 'o' then
--     -- vim.opt.fileencoding = "korea"
--     vim.opt.fileencoding = "utf-8"
-- end

-- vim.opt.previewheight = 16
-- vim.opt.pastetoggle = "<c-n><c-p>"



