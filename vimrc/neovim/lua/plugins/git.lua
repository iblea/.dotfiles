return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = false,
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end, "Next Git hunk")

        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end, "Previous Git hunk")

        map("n", "<leader>hs", gitsigns.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gitsigns.reset_hunk, "Reset hunk")
        map("v", "<leader>hs", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage selected hunk")
        map("v", "<leader>hr", function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset selected hunk")
        map("n", "<leader>hS", gitsigns.stage_buffer, "Stage buffer")
        map("n", "<leader>hR", gitsigns.reset_buffer, "Reset buffer")
        map("n", "<leader>hp", gitsigns.preview_hunk, "Preview hunk")
        map("n", "<leader>hb", function()
          gitsigns.blame_line({ full = true })
        end, "Blame current line")
        map("n", "<leader>hB", gitsigns.toggle_current_line_blame, "Toggle line blame")
        map("n", "<leader>hd", gitsigns.diffthis, "Diff current file")
        map("n", "<leader>hD", function()
          gitsigns.diffthis("~")
        end, "Diff current file against previous revision")
      end,
    },
  },
  {
    "tpope/vim-fugitive",
    cmd = {
      "G",
      "Git",
      "GBrowse",
      "Gclog",
      "GDelete",
      "Gdiffsplit",
      "Gedit",
      "Ghdiffsplit",
      "Gllog",
      "GMove",
      "Gread",
      "Gvdiffsplit",
      "Gwrite",
    },
    keys = {
      { "<leader>gg", "<cmd>Git<cr>", desc = "Git status" },
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
      { "<leader>gv", "<cmd>Gvdiffsplit<cr>", desc = "Vertical Git diff" },
      { "<leader>gl", "<cmd>0Gclog<cr>", desc = "Current file Git log" },
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewFocusFiles",
      "DiffviewOpen",
      "DiffviewRefresh",
      "DiffviewToggleFiles",
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>gD", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
      { "<leader>gF", "<cmd>DiffviewFileHistory %<cr>", desc = "Current file history" },
      { "<leader>gL", "<cmd>DiffviewFileHistory<cr>", desc = "Repository history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
    },
    opts = function()
      local actions = require("diffview.config").actions

      return {
        view = {
          default = {
            layout = "diff2_horizontal",
          },
          merge_tool = {
            layout = "diff3_mixed",
          },
          file_history = {
            layout = "diff2_horizontal",
          },
        },
        keymaps = {
          file_panel = {
            ["f"] = false,
            { "n", "zF", actions.toggle_flatten_dirs, { desc = "Toggle flatten directories" } },
          },
        },
      }
    end,
  },
}
