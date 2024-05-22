return {
    "tanvirtin/monokai.nvim",
    event = "VimEnter",
    dependencies = { },
    config = function()
        require('monokai').setup {}
	-- require('monokai').setup { palette = require('monokai').pro }
    end
}
