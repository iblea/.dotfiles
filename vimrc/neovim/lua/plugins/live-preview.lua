-- 브라우저 실시간 마크다운 프리뷰 (mermaid/KaTeX 로컬 번들, 외부 런타임 불필요)
-- :LivePreview start / close, nvim 종료 시 서버 자동 정리
return {
  "brianhuster/live-preview.nvim",
  cmd = "LivePreview",
  keys = {
    {
      "<leader>o",
      function()
        -- 현재 nvim 인스턴스의 서버 기준 토글
        if require("livepreview").is_running() then
          vim.cmd("LivePreview close")
        else
          vim.cmd("LivePreview start")
        end
      end,
      desc = "Toggle LivePreview",
    },
  },
}
