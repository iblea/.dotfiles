local api = vim.api

api.nvim_set_var("lsp_servers", {
  "bashls",
  "cssls",
  "clangd",
  "lua_ls"
})

api.nvim_set_var("lsp_linters", {
})

api.nvim_set_var("lsp_formatters", {
})

api.nvim_set_var("extras", {
  "biome",
})
