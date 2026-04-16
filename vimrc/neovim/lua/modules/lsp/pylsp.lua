local M = {}

M.setup = function(on_attach, capabilities)
  vim.lsp.config("pylsp", {
    on_attach = on_attach,
    capabilities = capabilities or {},
    settings = {
      pylsp = {
        plugins = {
          pycodestyle = {
            maxLineLength = 120,
          },
        },
      },
    },
  })
  vim.lsp.enable("pylsp")
end

return M
