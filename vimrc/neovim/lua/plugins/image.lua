return {
  "3rd/image.nvim",
  build = false,
  event = "VimEnter",
  opts = {
    backend = "sixel",
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
          vim.cmd("edit")
          vim.notify("Image rendering enabled", vim.log.levels.INFO)
        end
      end,
      desc = "Toggle image rendering",
    },
  },
}
