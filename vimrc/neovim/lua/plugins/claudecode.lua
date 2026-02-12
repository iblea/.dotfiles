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

    -- diff 모드 진입 시 tmux window 자동 이동
    local last_switch_time = 0
    vim.api.nvim_create_autocmd("OptionSet", {
      pattern = "diff",
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

        local is_diff_on = vim.v.option_new == true or vim.v.option_new == 1 or vim.v.option_new == "1"

        if is_diff_on then
          -- diff ON: diff가 아닌 버퍼 삭제 + 분할 창 크기 균등화 + tmux window 자동 이동
          vim.defer_fn(function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
                local is_diff_buf = false
                for _, win in ipairs(vim.fn.win_findbuf(buf)) do
                  if vim.wo[win].diff then
                    is_diff_buf = true
                    break
                  end
                end
                if not is_diff_buf then
                  pcall(vim.api.nvim_buf_delete, buf, { force = true })
                end
              end
            end
            vim.cmd("wincmd =")
            vim.fn.jobstart("tmux select-window -t 2", { detach = true })
          end, 200)
        else
          -- diff OFF: 모든 버퍼 삭제 후 tmux window 이동
          vim.schedule(function()
            vim.cmd("%bw!")
            vim.fn.jobstart("tmux select-window -t 1", { detach = true })
          end)
        end
      end,
    })
  end,
}