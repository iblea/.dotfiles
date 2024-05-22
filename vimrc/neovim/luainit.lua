

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

vim.g.mapleader = "q"

-- General settings
require("modules.globals")

require("lazy").setup("plugins", {
  defaults = { lazy = true },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrw",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
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
-- require("themes")

-- require("cmp-tw2css").setup()
-- require("classy").setup()
