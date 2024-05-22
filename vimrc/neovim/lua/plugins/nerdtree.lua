return {
  "preservim/nerdtree",
  event = "VimEnter",
  config = function()
    vim.api.nvim_command('let NERDTreeShowHidden=1')
  end
}

