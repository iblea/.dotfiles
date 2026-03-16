return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  event = "VeryLazy",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("nvim-treesitter-textobjects").setup({
      select = {
        enable = true,
        lookahead = true,
      },
    })

    local select_textobject = require("nvim-treesitter-textobjects.select").select_textobject
    local keymaps = {
      ["af"] = "@function.outer",
      ["if"] = "@function.inner",
      ["ab"] = "@block.outer",
      ["ib"] = "@block.inner",
      ["ac"] = "@call.outer",
      ["ic"] = "@call.inner",
      ["ai"] = "@conditional.outer",
      ["ii"] = "@conditional.inner",
      ["al"] = "@loop.outer",
      ["il"] = "@loop.inner",
    }
    for key, query in pairs(keymaps) do
      vim.keymap.set({ "x", "o" }, key, function()
        select_textobject(query, "textobjects")
      end)
    end
  end,
}
