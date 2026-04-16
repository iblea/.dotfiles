local M = {}

M.setup = function(on_attach, capabilities)
  vim.lsp.config("pyright", {
    root_markers = {
      "pyrightconfig.json",
      "pyproject.toml",
      "setup.py",
      "setup.cfg",
    },
    on_attach = on_attach,
    capabilities = capabilities or {},
    settings = {
      python = {
        analysis = {
          typeCheckingMode = "basic",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "openFilesOnly",
        },
      },
    },
  })
  vim.lsp.enable("pyright")
end

return M
