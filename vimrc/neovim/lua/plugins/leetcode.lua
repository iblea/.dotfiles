return {
  "kawre/leetcode.nvim",
  lazy = false,
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "3rd/image.nvim",
  },
  opts = {
    lang = "cpp",
    image_support = true,
  },
  config = function(_, opts)
    require("leetcode").setup(opts)
    -- nui.nvim이 split 생성 시 winfixwidth/winfixheight를 켜서
    -- wincmd = 가 안 먹히는 문제 해결
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "leetcode",
      callback = function()
        vim.schedule(function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            pcall(vim.api.nvim_set_option_value, "winfixwidth", false, { win = win })
            pcall(vim.api.nvim_set_option_value, "winfixheight", false, { win = win })
          end
        end)
      end,
    })
  end,
}
