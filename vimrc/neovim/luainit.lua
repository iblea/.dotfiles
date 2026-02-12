

-- https://github.com/krapjost/nvim-lua-guide-kr

function get_lazy_path()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
    })
  end
  return lazypath
end



local lazypath = get_lazy_path()
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = "s"
vim.keymap.set("n", "s", "<Nop>")

-- General settings
require("modules.globals")

require("lazy").setup("plugins", {
  defaults = { lazy = true },
  performance = {
    rtp = {
      disabled_plugins = {
        -- "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrw",
        -- "netrwPlugin",
        -- "tarPlugin",
        -- "tohtml",
        "tutor",
        -- "zipPlugin",
      },
    },
  },
  ui = {
    border = "rounded",
  },
})


require("modules.utils")
-- require("modules.keymappings")
require("modules.options")
-- require("modules.autocmd")
require("themes")

vim.cmd('colorscheme monokai-pro-classic')
-- vim.cmd('colorscheme monokai-pro')

-- require("cmp-tw2css").setup()
-- require("classy").setup()

if vim.env.TMUX_CLAUDECODE_IDE_NVIM == "1" then
  -- split 방향 토글 (horizontal <-> vertical) + 크기 균등화
  vim.keymap.set("n", "<leader>nn", function()
    local layout = vim.fn.winlayout()
    if layout[1] == "col" then
      vim.cmd("wincmd H")
    elseif layout[1] == "row" then
      vim.cmd("wincmd J")
    end
    vim.cmd("wincmd =")
  end, { desc = "Toggle split direction" })

  -- 분할 창 크기 균등화
  vim.keymap.set("n", "<C-=>", "<C-w>=", { desc = "Equalize window sizes" })

  vim.opt.wrap = true
  vim.opt.diffopt:append("followwrap")
end

