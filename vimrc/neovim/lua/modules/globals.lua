local api = vim.api

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
api.nvim_set_var("lsp_servers", {
  -- "bashls",
  -- "cssls",
  -- "clangd",
  "lua_ls",
  -- "pylsp"
})

api.nvim_set_var("lsp_linters", {
})

api.nvim_set_var("lsp_formatters", {
})

api.nvim_set_var("extras", {
  -- "biome",
})
