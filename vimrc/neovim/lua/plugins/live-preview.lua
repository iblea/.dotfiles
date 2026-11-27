-- 브라우저 실시간 마크다운 프리뷰 (mermaid/KaTeX 로컬 번들, 외부 런타임 불필요)
-- :LivePreview start / close, nvim 종료 시 서버 자동 정리

-- 서버 가동 중 + webroot 하위 파일이면 재시작 없이 브라우저만 오픈, 그 외 start
-- (serverObj.webroot 등 플러그인 내부 API 의존)
local function open_preview()
  local lp = require("livepreview")
  local utils = require("livepreview.utils")
  local file = vim.api.nvim_buf_get_name(0)
  local rel = lp.is_running()
    and utils.supported_filetype(file)
    and utils.get_relative_path(file, lp.serverObj.webroot)
  if not rel then
    vim.cmd("LivePreview start")
    return
  end
  local cfg = require("livepreview.config").config
  utils.open_browser(("http://%s:%d/%s"):format(cfg.address, cfg.port, vim.uri_encode(rel)), cfg.browser)
end

return {
  "brianhuster/live-preview.nvim",
  cmd = "LivePreview",
  keys = {
    { "<leader>oi", open_preview, desc = "Open LivePreview" },
    { "<leader>ou", "<cmd>LivePreview close<cr>", desc = "Stop LivePreview" },
  },
}
