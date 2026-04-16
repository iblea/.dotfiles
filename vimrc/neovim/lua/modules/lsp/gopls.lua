local M = {}

M.setup = function(on_attach, capabilities)
  vim.lsp.config("gopls", {
    root_markers = {
      "go.mod",
      "go.sum",
      "go.work",
    },
    on_attach = on_attach,
    capabilities = capabilities or {},
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
          shadow = true,
        },
        staticcheck = true,
        gofumpt = true,
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
      },
    },
  })
  vim.lsp.enable("gopls")
end

return M
