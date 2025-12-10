-- return {
--     'MeanderingProgrammer/render-markdown.nvim',
--     after = { 'nvim-treesitter' },
--     -- requires = { 'echasnovski/mini.nvim', opt = true }, -- if you use the mini.nvim suite
--     -- requires = { 'echasnovski/mini.icons', opt = true }, -- if you use standalone mini plugins
--     -- requires = { 'nvim-tree/nvim-web-devicons', opt = true }, -- if you prefer nvim-web-devicons
--     config = function()
--         require('render-markdown').setup({})
--     end,
-- }

return {
    'MeanderingProgrammer/render-markdown.nvim',
    event = "VimEnter",
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    -- ---@module 'render-markdown'
    -- ---@type render.md.UserConfig
    config = function()
        require('render-markdown').setup({
            render_modes = { 'n', 'c', 'nt' },
        })
        require('render-markdown').enable()
    end,
}
