return {
  "coder/claudecode.nvim",
  event = "VeryLazy",
  dependencies = { "folke/snacks.nvim" },
  config = function()
    require("claudecode").setup({
      terminal_cmd = "~/.local/bin/claude",
      terminal = {
        provider = "none",
      },
    })

    -- Claude 모드 토글 (기본: off)
    vim.g.claude_tmux_auto_switch = false

    vim.keymap.set("n", "<leader>cc", function()
      vim.g.claude_tmux_auto_switch = not vim.g.claude_tmux_auto_switch
      vim.notify("Claude tmux auto-switch: " .. (vim.g.claude_tmux_auto_switch and "ON" or "OFF"))
    end, { desc = "Toggle Claude tmux auto-switch" })

    -- Claude 연결 시 파일 열면 tmux window 자동 이동
    local last_switch_time = 0
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        -- TMUX_CLAUDECODE_IDE_NVIM=1 일 때만 동작
        if vim.env.TMUX_CLAUDECODE_IDE_NVIM ~= "1" then
          return
        end

        -- debounce (500ms)
        local now = vim.loop.now()
        if now - last_switch_time < 500 then
          return
        end
        last_switch_time = now

        vim.fn.jobstart("tmux select-window -l", { detach = true })
      end,
    })
  end,
}
