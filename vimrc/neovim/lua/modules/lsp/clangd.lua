local lspconfig = require("lspconfig")

local M = {}

M.setup = function(on_attach, capabilities)
  lspconfig.clangd.setup({
    cmd = { "clangd" } ,
    filetypes = { "c", "cpp", "h", "hpp" },
    root_dir = lspconfig.util.root_pattern(
      '.clangd',
      '.clang-tidy',
      '.clang-format',
      'compile_commands.json',
      'compile_flags.txt',
      'configure.ac',
      '.git'
    ),
    single_file_support = true
  })
end

return M
