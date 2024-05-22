local lspconfig = require("lspconfig")

local M = {}

M.setup = function(on_attach, capabilities)
  lspconfig.lua_ls.setup({
    on_attach = on_attach,
    capabilities = capabilities or {},
    single_file_support = true
  })

end

return M
