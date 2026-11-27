local ib = require("modules.image_backend")

return {
  "3rd/image.nvim",
  build = false,
  init = function()
    -- tmux + sixel: tmux가 alternate screen에서 sixel을 유지하지 못하는 문제 우회
    -- 플러그인 파일을 수정하지 않고, 메모리에서 sixel 백엔드를 패치하여
    -- tmux passthrough(\ePtmux;...\e\\)로 외부 터미널에 직접 sixel 전달
    if not vim.env.TMUX then return end

    package.preload["image/backends/sixel"] = function()
      local path = vim.fn.stdpath("data") .. "/lazy/image.nvim/lua/image/backends/sixel.lua"
      local f = io.open(path, "r")
      if not f then return end
      local content = f:read("*a")
      f:close()

      local old = "  -- sixel data\n  sequence = sequence .. wrapped_data"
      local s, e = content:find(old, 1, true)
      if s then
        local new = table.concat({
          "  -- sixel data (tmux passthrough)",
          '  if utils.tmux.is_tmux and utils.tmux.has_passthrough then',
          '    sequence = sequence .. "\\27Ptmux;" .. wrapped_data:gsub("\\27", "\\27\\27") .. "\\27\\\\"',
          "  else",
          "    sequence = sequence .. wrapped_data",
          "  end",
        }, "\n")
        content = content:sub(1, s - 1) .. new .. content:sub(e + 1)
      end

      local chunk, err = load(content, "@" .. path)
      if not chunk then error(err) end
      return chunk()
    end
  end,
  cond = vim.fn.executable("magick") == 1,
  event = "VimEnter",
  opts = {
    backend = ib.is_ghostty() and "kitty" or "sixel",
    kitty_method = vim.env.TMUX and "unicode-placeholders" or "normal",
    processor = "magick_cli",
    integrations = {
      markdown = {
        -- snacks.image 사용 시 문서 이미지는 snacks 담당
        enabled = not ib.use_snacks(),
        clear_in_insert_mode = false,
        download_remote_images = true,
        filetypes = { "markdown", "vimwiki" },
      },
    },
    max_height_window_percentage = 50,
    tmux_show_only_in_active_window = true,
    -- snacks.image 사용 시 이미지 파일 열기도 snacks 담당
    hijack_file_patterns = ib.use_snacks() and {} or { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
  },
  config = function(_, opts)
    local image = require("image")
    image.setup(opts)
    image.disable()

    -- kitty unicode-placeholders 잔상 임시 대응
    -- placeholder를 tty에 직접 출력하므로 nvim이 다시 그리지 않는 셀에 잔상 발생
    -- 화면 변경 시 전체 redraw 후 렌더된 이미지 강제 재렌더 (sixel 백엔드 방식 모방)
    if opts.backend == "kitty" then
      local timer = vim.uv.new_timer()
      local function redraw_images()
        if not image.is_enabled() or #image.get_images() == 0 then return end
        vim.cmd("noautocmd mode")
        vim.schedule(function()
          for _, img in ipairs(image.get_images()) do
            if img.is_rendered then
              img.is_rendered = false -- 동일 위치 렌더 skip 회피
              img:render()
            end
          end
        end)
      end
      vim.api.nvim_create_autocmd({ "WinScrolled", "WinResized", "TextChanged", "InsertLeave", "BufWinEnter" }, {
        group = vim.api.nvim_create_augroup("ImageGhostRedraw", { clear = true }),
        callback = function()
          -- 연속 스크롤 시 마지막 이벤트 기준 1회 처리
          timer:stop()
          timer:start(50, 0, vim.schedule_wrap(redraw_images))
        end,
      })
    end
  end,
  keys = {
    {
      "<leader>ti",
      function()
        if ib.use_snacks() then return ib.toggle_snacks() end
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
