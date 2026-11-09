

vim.o.exrc = true
vim.o.secure = false

-- globaldir를 명시적으로 설정하여 LSP spawn 등으로 OS cwd가 오염되어도
-- :pwd가 영향받지 않도록 방어 (neovim은 globaldir 미설정 시 OS getcwd()를 그대로 반환)
vim.api.nvim_set_current_dir(vim.fn.getcwd())

vim.g.fileline_space = vim.g.fileline_space or 0

-- https://github.com/krapjost/nvim-lua-guide-kr

function get_lazy_path()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
    })
  end
  return lazypath
end



local lazypath = get_lazy_path()
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = "s"
vim.keymap.set({"n", "v"}, "s", "<Nop>")

-- General settings
require("modules.globals")

require("lazy").setup("plugins", {
  defaults = { lazy = true },
  performance = {
    rtp = {
      disabled_plugins = {
        -- "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrw",
        -- "netrwPlugin",
        -- "tarPlugin",
        -- "tohtml",
        "tutor",
        -- "zipPlugin",
      },
    },
  },
  ui = {
    border = "rounded",
  },
})


require("modules.utils")
require("modules.keymappings")
require("modules.options")
require("modules.autocmd")
require("themes")

vim.cmd('colorscheme monokai-pro-classic')
-- vim.cmd('colorscheme monokai-pro')

-- require("cmp-tw2css").setup()
-- require("classy").setup()

if vim.env.TMUX_AIAGENT_IDE_NVIM == "1" then
  -- split 방향 토글 (horizontal <-> vertical) + 크기 균등화
  vim.keymap.set("n", "<leader>wc", function()
    local layout = vim.fn.winlayout()
    if layout[1] == "col" then
      vim.cmd("wincmd H")
    elseif layout[1] == "row" then
      vim.cmd("wincmd J")
    end
    vim.cmd("wincmd =")
  end, { desc = "Toggle split direction" })

  -- 분할 창 크기 균등화
  vim.keymap.set("n", "<C-=>", "<C-w>=", { desc = "Equalize window sizes" })

  vim.opt.wrap = true
  vim.opt.diffopt:append("followwrap")
end

-- TMUX 활성화 시 키매핑 활성화 (window/pane 체크는 실행 시점에 동적으로 수행)
if vim.env.TMUX or vim.env.LC_TMUX then
  local tmux_sock = (not vim.env.TMUX and vim.env.LC_TMUX) and vim.env.LC_TMUX_SOCKET or nil
  local function tmux(args)
    local cmd = {"tmux"}
    if tmux_sock then
      table.insert(cmd, "-S")
      table.insert(cmd, tmux_sock)
    end
    for _, a in ipairs(args) do
      table.insert(cmd, a)
    end
    return vim.fn.system(cmd)
  end

  -- 페인이 AI agent 페인인지 체크 (.zshrc/.bashrc 에서 set-option -p @is_aiagent_code 로 마킹)
  -- macOS는 ps eww 로 다른 프로세스의 환경변수를 못 가져오기 때문에 tmux pane option 으로 판별
  local function has_aiagent_env(target_pane)
    local val = tmux({"show-options", "-pqv", "-t", target_pane, "@is_aiagent_code"}):gsub("%s+$", "")
    return val ~= ""
  end

  -- 전송 대상 페인 결정
  -- 반환: { target = "...", focus = "window"|"pane" } 또는 nil (전송 안함)
  local function resolve_target()
    local cur_win = tmux({"display-message", "-p", "#{window_index}"}):gsub("%s+$", "")
    local cur_pane = tmux({"display-message", "-p", "#{pane_index}"}):gsub("%s+$", "")

    -- 현재가 window 1, pane 1 (claude code 자신) 이면 전송 안함
    if cur_win == "1" and cur_pane == "1" then
      return nil
    end

    -- 현재 페인이 1번이 아닌 경우(페인이 여러 개), 1번 페인의 AIAGENTCODE 체크
    if cur_pane ~= "1" then
      local first_pane = cur_win .. ".1"
      if has_aiagent_env(first_pane) then
        return { target = first_pane, focus = "pane" }
      end
    end

    -- 기본: 1번 윈도우 1번 페인
    return { target = ":1", focus = "window" }
  end

  local function focus_target(info)
    if info.focus == "pane" then
      tmux({"select-pane", "-t", info.target})
    elseif info.focus == "window_pane" then
      tmux({"select-window", "-t", info.target:match("^[^.]+")})
      tmux({"select-pane", "-t", info.target})
    else
      tmux({"select-window", "-t", info.target})
    end
  end

  -- claude code 페인의 pwd 기준 경로 계산
  local function get_claude_file_path(target_pane)
    local file_path = vim.fn.expand("%:p")

    -- LC_TMUX_SOCKET 경유(SSH) 시 pane_current_path가 로컬 경로라 상대경로 계산 불가
    if tmux_sock then
      return file_path
    end

    local claude_pwd = tmux({"display-message", "-p", "-t", target_pane, "#{pane_current_path}"})
    claude_pwd = claude_pwd:gsub("%s+$", "")

    local function split_path(path)
      local parts = {}
      for part in path:gmatch("[^/]+") do
        table.insert(parts, part)
      end
      return parts
    end

    local base_parts = split_path(claude_pwd)
    local target_parts = split_path(file_path)

    local common = 0
    for i = 1, math.min(#base_parts, #target_parts) do
      if base_parts[i] == target_parts[i] then
        common = i
      else
        break
      end
    end

    local rel_parts = {}
    for _ = common + 1, #base_parts do
      table.insert(rel_parts, "..")
    end
    for i = common + 1, #target_parts do
      table.insert(rel_parts, target_parts[i])
    end
    return table.concat(rel_parts, "/")
  end

  -- 파일 참조 문자열 생성 및 대상 페인 전송 (start_line 없으면 파일 전체)
  local function send_ref(info, start_line, end_line)
    local path = info.abs and vim.fn.expand("%:p") or get_claude_file_path(info.target)
    local ref
    if not start_line then
      ref = "@" .. path
    else
      local sep = (vim.g.fileline_space == 1) and " " or ""
      if start_line == end_line then
        -- ref = string.format("@%s%s#L%d", path, sep, start_line)
        ref = string.format("@%s%s:%d", path, sep, start_line)
      else
        -- ref = string.format("@%s%s#L%d-#L%d", path, sep, start_line, end_line)
        ref = string.format("@%s%s:%d-%d", path, sep, start_line, end_line)
      end
    end

    tmux({"send-keys", "-t", info.target, "-l", ref .. " "})
    focus_target(info)
  end

  -- visual 선택 라인 범위 (start <= end 정렬)
  local function visual_range()
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
    return start_line, end_line
  end

  -- 입력값 → 전송 대상 변환
  --   ""          : <leader>b 기본 대상
  --   "N"         : N번 윈도우 1번 페인
  --   ".N" / " N" : 현재 윈도우 N번 페인
  --   "W.P"       : W번 윈도우 P번 페인
  --   끝에 'a' 또는 공백 : 절대경로 전송 (예: "2.1a", "2.1 ", "a")
  -- 반환: info 또는 nil, 오류 메시지
  local function parse_target(input)
    -- 끝의 'a' 또는 공백 한 글자: 절대경로 지정자 분리
    local body, suffix = input:match("^(.-)([a ]?)$")
    local abs = suffix ~= ""

    if body == "" then
      local info = resolve_target()
      if info then info.abs = abs end
      return info
    end

    local win, pane = body:match("^(%d+)%.(%d+)$")
    if not win then
      win = body:match("^(%d+)$")
      pane = win and "1"
    end
    if not win then
      pane = body:match("^[. ](%d+)$")
      if pane then
        win = tmux({"display-message", "-p", "#{window_index}"}):gsub("%s+$", "")
      end
    end
    if not win then
      return nil, "잘못된 입력: '" .. input .. "'"
    end

    -- 대상 존재 확인 및 현재 페인(nvim 자신) 전송 방지
    -- display-message는 없는 대상도 exit 0 이므로 결과값 비교로 판별
    local target = tonumber(win) .. "." .. tonumber(pane)
    local resolved = tmux({"display-message", "-p", "-t", target, "#{window_index}.#{pane_index}"}):gsub("%s+$", "")
    if resolved ~= target then
      return nil, "대상 없음: " .. target
    end
    local current = tmux({"display-message", "-p", "#{window_index}.#{pane_index}"}):gsub("%s+$", "")
    if resolved == current then
      return nil, "현재 페인에는 전송 불가: " .. target
    end
    return { target = target, focus = "window_pane", abs = abs }
  end

  -- 전송 대상 입력 후 전송 (Esc 취소 시 미전송)
  local function prompt_and_send(start_line, end_line)
    vim.ui.input({ prompt = "Send to [Enter: auto | N | .N | W.P] (+a/space: abs): " }, function(input)
      if input == nil then return end
      local info, err = parse_target(input)
      if not info then
        if err then vim.notify(err, vim.log.levels.WARN) end
        return
      end
      send_ref(info, start_line, end_line)
    end)
  end

  -- visual 선택 범위 확정 후 대상 입력 및 전송
  local function prompt_and_send_visual()
    local start_line, end_line = visual_range()
    vim.cmd("normal! \27")
    prompt_and_send(start_line, end_line)
  end

  -- normal mode: 파일 전체를 claude code에 전송 (SSH 경유 시 대상 입력)
  vim.keymap.set("n", "<leader>b", function()
    if tmux_sock then return prompt_and_send() end
    local info = resolve_target()
    if not info then return end
    send_ref(info)
  end, { desc = "Send file reference to Claude Code" })

  -- visual mode: 선택한 라인 범위를 claude code에 전송 (SSH 경유 시 대상 입력)
  vim.keymap.set("v", "<leader>b", function()
    if tmux_sock then return prompt_and_send_visual() end
    local info = resolve_target()
    if not info then return end
    send_ref(info, visual_range())
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end, { desc = "Send file reference to Claude Code" })

  -- normal mode: 대상 선택 후 파일 전체 전송
  vim.keymap.set("n", "<leader>n", function()
    prompt_and_send()
  end, { desc = "Send file reference to selected tmux pane" })

  -- visual mode: 대상 선택 후 선택 라인 범위 전송
  vim.keymap.set("v", "<leader>n", prompt_and_send_visual, { desc = "Send file reference to selected tmux pane" })

  -- setreg는 TextYankPost를 트리거하지 않아서 tmux OSC 52 autocmd가 동작하지 않음
  local function copy_osc52(text)
    vim.fn.setreg("+", text)
    vim.api.nvim_chan_send(2, string.format('\027]52;c;%s\027\\', vim.base64.encode(text)))
  end

  -- normal mode: 파일 절대경로를 클립보드에 복사
  local function copy_abs_path()
    local path = vim.fn.expand("%:p")
    copy_osc52(path)
    print("absolute path (normal) copy!")
  end
  vim.keymap.set("n", "<leader>pa", copy_abs_path, { desc = "Copy absolute path to clipboard" })
  vim.keymap.set("n", "<leader>m", copy_abs_path, { desc = "Copy absolute path to clipboard" })

  -- visual mode: 파일 절대경로 + 라인 범위를 클립보드에 복사
  local function copy_abs_path_lines()
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end

    local file_path = vim.fn.expand("%:p")
    local ref
    if start_line == end_line then
      ref = string.format("%s:%d", file_path, start_line)
    else
      ref = string.format("%s:%d-%d", file_path, start_line, end_line)
    end

    copy_osc52(ref)
    print("absolute path + line (visual) copy!")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end
  vim.keymap.set("v", "<leader>pa", copy_abs_path_lines, { desc = "Copy absolute path with lines to clipboard" })
  vim.keymap.set("v", "<leader>m", copy_abs_path_lines, { desc = "Copy absolute path with lines to clipboard" })

  -- normal mode: 파일 절대경로 출력
  vim.keymap.set("n", "<leader>pp", function()
    print(vim.fn.expand("%:p"))
  end, { desc = "Print absolute path" })

  -- visual mode: 파일 절대경로 + 라인 범위 출력
  vim.keymap.set("v", "<leader>pp", function()
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end

    local file_path = vim.fn.expand("%:p")
    local ref
    if start_line == end_line then
      ref = string.format("%s:%d", file_path, start_line)
    else
      ref = string.format("%s:%d-%d", file_path, start_line, end_line)
    end

    print(ref)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end, { desc = "Print absolute path with lines" })
end

-- Project-local config loader
-- 프로젝트 루트의 .nvim.lua, .vscode/.nvim.lua 자동 로드
local _loaded_project_configs = {}

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
  callback = function()
    local buf_dir = vim.fn.expand("%:p:h")

    local root_match = vim.fs.find({ ".git", ".nvim.lua", ".vscode" }, {
      upward = true,
      path = buf_dir,
    })
    if #root_match == 0 then return end
    local root = vim.fn.fnamemodify(root_match[1], ":h")
    -- local root = vim.fn.getcwd()

    if _loaded_project_configs[root] then return end
    _loaded_project_configs[root] = true

    local targets = {
      root .. "/.nvim.lua",
      root .. "/.vscode/.nvim.lua",
    }
    for _, path in ipairs(targets) do
      if vim.fn.filereadable(path) == 1 then
        -- local content = vim.secure.read(path)
        -- if content then
        --   local fn = load(content)
        --   if fn then fn() end
        -- end
        dofile(path)
      end
    end
  end,
})

