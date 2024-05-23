vim.api.nvim_create_autocmd("ColorScheme",
  {
    pattern = "*",
    callback = function()
      -- vim.api.nvim_set_hl(0, "CursorLineNr", { cterm=bold, bold=true })
      -- vim.cmd(
      --   'highlight! Normal ctermfg=231 ctermbg=NONE guifg=#f8f8f2 guibg=NONE'
      -- )
      vim.cmd('source '..os.getenv("HOME")..'/.dotfiles/vimrc/neovim/lua/themes/init.vimrc')
      -- vim.api.nvim_command('source '..os.getenv("HOME")..'/.dotfiles/vimrc/neovim/lua/themes/init.vimrc')
    end
  }
)
