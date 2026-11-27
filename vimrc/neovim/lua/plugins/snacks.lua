-- 프로토타입: ghostty 환경 문서 이미지 렌더링을 snacks.image로 대체
-- 롤백: lua/modules/image_backend.lua의 use_snacks_on_ghostty = false
--   false 시 빈 spec 반환 → claudecode 의존성으로만 로드되는 기존 상태 유지
--   (같은 플러그인 spec에 cond를 걸면 claudecode 의존성까지 차단되므로 cond 미사용)
local ib = require("modules.image_backend")
if not ib.use_snacks() then return {} end

return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  init = function()
    -- tmux 내부에서 snacks의 ghostty 미감지 방지
    vim.env.SNACKS_GHOSTTY = "true"
  end,
  opts = {
    image = {
      doc = {
        -- 기본 80칸 제한 시 다이어그램 글자 판독 불가 → 창 폭까지 허용 (snacks가 창 크기로 재제한)
        max_width = 999,
        max_height = 40,
      },
    },
  },
  config = function(_, opts)
    require("snacks").setup(opts)
    ib.setup_snacks()
  end,
}
