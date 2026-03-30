local indent = 4 -- num of spaces for indentation
local et_stat = false

-- vim.opt.shell=/bin/zsh

vim.opt.background = "dark"
vim.opt.autoindent = true -- auto indent when starting a new line
vim.opt.breakindent = true -- wrapped line is visually indented
-- SSH + TMUX 환경에서 OSC 52로 클립보드 전달 (neovim 0.10+)
-- if vim.env.LC_TMUX and (vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT) then
if vim.env.LC_TMUX then
  local ok, osc52 = pcall(require, 'vim.ui.clipboard.osc52')
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      -- Ghostty + tmux에서 clipboard provider copy context 내의
      -- nvim_chan_send가 동작하지 않는 문제로 TextYankPost에서 처리
      ['+'] = function(lines) end,
      ['*'] = function(lines) end,
    },
    paste = ok and {
      ['+'] = osc52.paste('+'),
      ['*'] = osc52.paste('*'),
    } or {
      ['+'] = function() return vim.fn.getreg('+', 1, true), vim.fn.getregtype('+') end,
      ['*'] = function() return vim.fn.getreg('*', 1, true), vim.fn.getregtype('*') end,
    },
  }
  vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
      local text = table.concat(vim.v.event.regcontents, '\n')
      -- linewise(V) yank 시 끝에 개행 추가 (vim 동작과 일치)
      if vim.v.event.regtype == 'V' then
        text = text .. '\n'
      end
      vim.api.nvim_chan_send(2, string.format('\027]52;c;%s\027\\', vim.base64.encode(text)))
    end,
  })
end
vim.opt.clipboard = "unnamed,unnamedplus"

vim.opt.laststatus=2
vim.opt.backup = false
vim.opt.swapfile = true
vim.opt.backupdir = '.,/tmp'
vim.opt.undodir = '.,/tmp'
vim.opt.directory = '.,/tmp'

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
vim.opt.title = true
vim.opt.titlestring = "nvim - %f"

-- set cst
-- set nocsverb

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.incsearch = true
vim.opt.magic = true

-- vim.opt.fixeol = false
-- vim.opt.fixendofline = false
-- vim.opt.eol = true

-- local lang_env = vim.api.nvim_command('echo $LANG')
-- if lang_env[0] == 'k' && lang_env[1] == 'o' then
--     -- vim.opt.fileencoding = "korea"
--     vim.opt.fileencoding = "utf-8"
-- end

-- vim.opt.previewheight = 16
-- vim.opt.pastetoggle = "<c-n><c-p>"


vim.opt.autochdir = false     -- :cd 명령어와 다를 것이 없다.

-- 외부에서 파일 변경 시 자동으로 다시 읽기
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  callback = function()
    if vim.fn.mode() ~= 'c' then
      vim.cmd('silent! checktime')
    end
  end,
})

