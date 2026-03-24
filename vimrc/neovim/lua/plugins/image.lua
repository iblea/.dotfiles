return {
  "3rd/image.nvim",
  build = false,
  cond = vim.fn.executable("magick") == 1,
  event = "VimEnter",
  opts = {
    backend = (vim.env.TERM_PROGRAM == "ghostty"
      or vim.env.LC_TERM_PROGRAM == "ghostty"
      or (vim.env.TERM or ""):find("ghostty"))
      and "kitty" or "sixel",
    processor = "magick_cli",
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = true,
        filetypes = { "markdown", "vimwiki" },
      },
    },
    max_height_window_percentage = 50,
    tmux_show_only_in_active_window = true,
    hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
  },
  config = function(_, opts)
    local image = require("image")
    image.setup(opts)
    image.disable()
  end,
  keys = {
    {
      "<leader>it",
      function()
        local image = require("image")
        if image.is_enabled() then
          image.disable()
          local ns = vim.api.nvim_create_namespace("image.nvim")
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) then
              vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
            end
          end
          vim.cmd("mode")
          vim.notify("Image rendering disabled", vim.log.levels.INFO)
        else
          image.enable()
          if vim.api.nvim_buf_get_name(0) ~= "" then
            vim.cmd("edit")
          end
          -- disable 상태에서 열린 버퍼는 state.images에 이미지가 등록되지 않음
          -- (Image:render()의 state.enabled 가드 때문)
          -- 이미지가 없으면 열린 윈도우의 버퍼를 스캔해서 직접 생성
          vim.schedule(function()
            if #image.get_images() > 0 then
              return
            end
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              local buf = vim.api.nvim_win_get_buf(win)
              local lines = vim.api.nvim_buf_get_lines(buf, 1, -1, false)
              for i, line in ipairs(lines) do
                for link in line:gmatch("%((http[s]?://%S+)%)") do
                  image.from_url(link, {
                    buffer = buf,
                    window = win,
                    with_virtual_padding = true,
                  }, function(img)
                    if img then img:render({ y = i + 1 }) end
                  end)
                end
              end
            end
          end)
          vim.notify("Image rendering enabled", vim.log.levels.INFO)
        end
      end,
      desc = "Toggle image rendering",
    },
  },
}
