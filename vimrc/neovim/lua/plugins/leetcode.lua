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
  build = "sed -i'' -e 's/vim.api.nvim_set_current_dir(config.storage.home:absolute())/vim.api.nvim_set_current_dir(vim.fn.getcwd())/' lua/leetcode.lua",
  config = function(_, opts)
    local lc_dir = vim.fn.stdpath("data") .. "/leetcode"
    local _orig_cwd = vim.fn.getcwd()

    require("leetcode").setup(opts)

    -- leetcode 파일 진입 시 cwd가 바뀌어 있으면 강제 복원
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if vim.fn.getcwd():find(lc_dir, 1, true) then
          pcall(vim.api.nvim_set_current_dir, _orig_cwd)
        end
      end,
    })

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
