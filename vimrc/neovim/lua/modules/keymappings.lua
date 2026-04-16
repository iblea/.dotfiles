local utils = require("modules.utils")
local map = utils.map

-- vim.g.mapleader = " "

-- LSP 미연결 시 <leader>u, <leader>i 키 오동작 방지 (글로벌 fallback)
-- LspAttach 시 버퍼 로컬 매핑이 덮어씀
local lsp_nop = function()
  vim.notify("No LSP attached", vim.log.levels.WARN)
end
local lsp_fallback_keys = {
  "u", "ud", "uD", "ur", "uT", "ui", "un", "ua", "uh", "uk", "us", "ut",
  "i", "id", "iD", "ir", "iT", "ii", "in", "ia", "ih", "ik", "is", "it", "iw",
}
for _, key in ipairs(lsp_fallback_keys) do
  vim.keymap.set("n", "<leader>" .. key, lsp_nop)
end
