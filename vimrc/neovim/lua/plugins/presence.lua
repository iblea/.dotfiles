return {
  "andweeb/presence.nvim",
  -- event = "VeryLazy",
  event = "VimEnter",
  config = function()
    local presence = require("presence")
	presence.setup({
      auto_update = true,
      -- main_image = "neovim",
      main_image = "file",
      client_id = "793271441293967371",
      log_level = nil,
      debounce_timeout = 100,
      enable_line_number = false,
      blacklist = {},
      buttons = true,
      file_assets = {},
      show_time = true,

      -- Rich Presence text options
      -- editing_text        = "Editing %s"
      -- file_explorer_text  = "Browsing %s",
      -- git_commit_text     = "Committing changes",
      -- plugin_manager_text = "Managing plugins",
      -- reading_text        = "Reading %s",
      -- workspace_text      = "Working on %s",
      -- line_number_text    = "Line %s out of %s",

      editing_text        = "Editing File",
      file_explorer_text  = "Browsing",
      git_commit_text     = "Committing changes",
      plugin_manager_text = "Managing plugins",
      reading_text        = "Reading File",
      workspace_text      = "Working",
      line_number_text    = "Working"
	})
  end,
}
