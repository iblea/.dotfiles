local u = require("modules.utils")
local lsp = vim.lsp
-- local capabilities = vim.lsp.protocol.make_client_capabilities()
local capabilities = vim.tbl_deep_extend(
  "force",
  vim.lsp.protocol.make_client_capabilities(),
  require("cmp_nvim_lsp").default_capabilities()
)

local border = {
  { "╭", "FloatBorder" },
  { "─", "FloatBorder" },
  { "╮", "FloatBorder" },
  { "│", "FloatBorder" },
  { "╯", "FloatBorder" },
  { "─", "FloatBorder" },
  { "╰", "FloatBorder" },
  { "│", "FloatBorder" },
}

local orig_util_open_floating_preview = lsp.util.open_floating_preview
function lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or border
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

vim.diagnostic.config({
  float = {
    source = "always",
    show_header = true,
  },
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = false,
})

local signs = { Error = "", Warn = "", Hint = "", Info = "" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon .. " ", texthl = hl, numhl = hl })
end

local win = require("lspconfig.ui.windows")
local _default_opts = win.default_opts

win.default_opts = function(options)
  local opts = _default_opts(options)
  opts.border = "rounded"
  return opts
end

local on_attach = function(client, bufnr)
  -- commands
  u.lua_command("LspFormatting", "vim.lsp.buf.format()")
  u.lua_command("LspHover", "vim.lsp.buf.hover()")
  u.lua_command("LspRename", "vim.lsp.buf.rename()")
  u.lua_command("LspDiagPrev", "vim.diagnostic.goto_prev()")
  u.lua_command("LspDiagNext", "vim.diagnostic.goto_next()")
  u.lua_command("LspDiagOpen", "vim.diagnostic.open_float({border='rounded'})")
  u.lua_command(
    "LspDiagLine",
    "vim.diagnostic.open_float(nil, global.lsp.border_opts)"
  )
  u.lua_command("LspTypeDef", "vim.lsp.buf.type_definition()")
  u.lua_command("LspDec", "vim.lsp.buf.declaration()")
  u.lua_command("LspDef", "vim.lsp.buf.definition()")
  u.lua_command("LspFindRef", "vim.lsp.buf.references()")
  u.lua_command("LspCodeAction", "require('cosmic-ui').code_actions()<cr>")
  u.lua_command(
    "LspRangeCodeAction",
    "require('cosmic-ui').range_code_actions()"
  )
  u.lua_command("LspSignatureHelp", "vim.lsp.buf.signature_help()")

  if client.name == "tsserver" then
    client.server_capabilities.documentFormattingProvider = false
  end

  if client.server_capabilities.inlayHintProvider then
    -- vim.lsp.inlay_hint.enable(0, true)
    -- vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    vim.lsp.inlay_hint.enable(bufnr, false)
  end

  require("illuminate").on_attach(client)
end

-- Configure sumneko_lua to support neovim Lua runtime APIs
-- require("neodev").setup()

local servers = vim.api.nvim_get_var("lsp_servers")

for _, server_name in ipairs(servers) do

  local server = "modules.lsp." .. server_name
  require(server).setup(on_attach, capabilities)
  ::continue::
end
