return {
  "kylechui/nvim-surround",
  version = "*",
  event = "VeryLazy",
  config = function()
    require("nvim-surround").setup({
      surrounds = {
        -- 여는 괄호 입력 시에도 공백 없이 감싸기 (기본값: "( ", " )")
        ["("] = { add = { "(", ")" } },
      },
    })
  end,
}
