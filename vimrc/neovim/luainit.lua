

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
-- require("modules.keymappings")
require("modules.options")
-- require("modules.autocmd")
require("themes")

vim.cmd('colorscheme monokai-pro-classic')
-- vim.cmd('colorscheme monokai-pro')

-- require("cmp-tw2css").setup()
-- require("classy").setup()

if vim.env.TMUX_CLAUDECODE_IDE_NVIM == "1" then
  -- split 방향 토글 (horizontal <-> vertical) + 크기 균등화
  vim.keymap.set("n", "<leader>nn", function()
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

  -- claude code 윈도우의 pwd 기준 상대경로 계산
  local function get_claude_relative_path()
    local file_path = vim.fn.expand("%:p")
    local claude_pwd = vim.fn.system("tmux display-message -p -t :1 '#{pane_current_path}'")
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

  -- normal mode: 파일 전체를 claude code에 전송
  vim.keymap.set("n", "<leader>b", function()
    local ref = "@" .. get_claude_relative_path()
    vim.fn.system({"tmux", "send-keys", "-t", ":1", "-l", ref .. " "})
    vim.fn.system({"tmux", "select-window", "-t", ":1"})
  end, { desc = "Send file reference to Claude Code" })

  -- visual mode: 선택한 라인 범위를 claude code에 전송
  vim.keymap.set("v", "<leader>b", function()
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end

    local relative_path = get_claude_relative_path()
    local ref
    if start_line == end_line then
      ref = string.format("@%s#L%d", relative_path, start_line)
    else
      ref = string.format("@%s#L%d-#L%d", relative_path, start_line, end_line)
    end

    vim.fn.system({"tmux", "send-keys", "-t", ":1", "-l", ref .. " "})
    vim.fn.system({"tmux", "select-window", "-t", ":1"})
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end, { desc = "Send file reference to Claude Code" })

  -- normal mode: 파일 절대경로를 클립보드에 복사
  vim.keymap.set("n", "<leader>pa", function()
    local path = vim.fn.expand("%:p")
    vim.fn.setreg("+", path)
    print("absolute path (normal) copy!")
  end, { desc = "Copy absolute path to clipboard" })

  -- visual mode: 파일 절대경로 + 라인 범위를 클립보드에 복사
  vim.keymap.set("v", "<leader>pa", function()
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

    vim.fn.setreg("+", ref)
    print("absolute path + line (visual) copy!")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end, { desc = "Copy absolute path with lines to clipboard" })

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

  vim.opt.wrap = true
  vim.opt.diffopt:append("followwrap")
end

