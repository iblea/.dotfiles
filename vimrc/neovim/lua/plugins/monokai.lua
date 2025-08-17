return {
    "iblea/monokai-pro.nvim",
    event = "VimEnter",
    dependencies = { },
    config = function()
        require("monokai-pro").setup({
            theme = 'monokai-pro-classic',
            filter = "classic"
            -- theme = 'monokai-pro',
            -- filter = "pro"
        })
        override = function()
            return {
                -- Normal = { bg = "#000000" }
            }
        end
        overrideScheme = function(cs, p, config, hp)
            local cs_override = {}
            -- local calc_bg = hp.blend(p.background, 0.75, '#000000')

            cs_override.editor = {
                -- background = calc_bg,
            }
            return cs_override
        end
    end
}

-- return {
--     { "tanvirtin/monokai.nvim" },
--     event = "VimEnter",
--     dependencies = { },
--     config = function()
--         require('monokai').setup {
--             palette = require('monokai').classic
--         }
--         -- require('monokai').setup { palette = require('monokai').pro }
--     end
-- }
