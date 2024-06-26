return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local parser_configs =
      require("nvim-treesitter.parsers").get_parser_configs()

    parser_configs.norg_meta = {
      install_info = {
        url = "https://github.com/nvim-neorg/tree-sitter-norg-meta",
        files = { "src/parser.c" },
        branch = "main",
      },
    }

    parser_configs.norg_table = {
      install_info = {
        url = "https://github.com/nvim-neorg/tree-sitter-norg-table",
        files = { "src/parser.c" },
        branch = "main",
      },
    }

    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "astro",
        "css",
        "go",
        "html",
        "http",
        "javascript",
        "json",
        "jsonc",
        "lua",
        "markdown",
        "markdown_inline",
        "scss",
        "tsx",
        "typescript",
        "query"
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
      autotag = {
        enable = true,
      },
      rainbow = {
        enable = true,
        extended_mode = true,
      },
      -- query_linter = {
      --   enable = true,
      --   use_virtual_text = true,
      --   lint_events = { "BufWrite", "CursorHold" },
      -- },
    })
  end,
}
