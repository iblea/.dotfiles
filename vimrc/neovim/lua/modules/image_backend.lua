-- 이미지 렌더링 플러그인 선택 (image.nvim / snacks.image)
-- ghostty: snacks.image (image.nvim kitty unicode-placeholders 잔상·크롭 문제 회피, 프로토타입)
-- 그 외 (iTerm2 등 sixel): image.nvim
local M = {}

-- 롤백 스위치: false 시 ghostty에서도 image.nvim 사용 (snacks 프로토타입 이전 상태)
M.use_snacks_on_ghostty = true

local ghostty_cache = nil
function M.is_ghostty()
  if ghostty_cache ~= nil then return ghostty_cache end
  local is_ghostty = vim.env.TERM_PROGRAM == "ghostty"
    or vim.env.LC_TERM_PROGRAM == "ghostty"
  if not is_ghostty and vim.env.TMUX then
    local result = vim.fn.system("tmux show-environment -g LC_TERM_PROGRAM 2>/dev/null")
    is_ghostty = result:find("ghostty") ~= nil
  end
  ghostty_cache = is_ghostty
  return is_ghostty
end

function M.use_snacks()
  return M.use_snacks_on_ghostty and M.is_ghostty()
end

-- snacks.image 문서 이미지 표시 상태 (기본: off, image.nvim과 동일)
M.snacks_enabled = false

-- doc.find_visible 래핑으로 off 상태의 inline 갱신 차단
function M.setup_snacks()
  local doc = Snacks.image.doc
  local find_visible = doc.find_visible
  doc.find_visible = function(buf, cb)
    if not M.snacks_enabled then return end
    return find_visible(buf, cb)
  end
end

function M.toggle_snacks()
  M.snacks_enabled = not M.snacks_enabled
  local langs = Snacks.image.langs()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "image" then
      if not M.snacks_enabled then
        Snacks.image.placement.clean(buf)
      elseif vim.b[buf].snacks_image_attached then
        -- attach된 버퍼는 inline 갱신 트리거
        pcall(vim.api.nvim_exec_autocmds, "BufWinEnter", { group = "snacks.image.inline." .. buf, buffer = buf })
      else
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        if lang and vim.tbl_contains(langs, lang) then Snacks.image.doc.attach(buf) end
      end
    end
  end
  vim.notify("Image rendering " .. (M.snacks_enabled and "enabled" or "disabled") .. " (snacks)", vim.log.levels.INFO)
end

return M
