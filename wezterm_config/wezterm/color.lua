
-- local wezterm = require 'wezterm'

local colors_ansi = {
    ansi = {
        'black',
        'maroon',
        'green',
        'olive',
        'navy',
        'purple',
        'teal',
        'silver',
    },
    brights = {
        'grey',
        'red',
        'lime',
        'yellow',
        'blue',
        'fuchsia',
        'aqua',
        'white',
    },
}

local colors_monokai = {
    ansi = {
        '#222121', -- Black
        '#dd6b87', -- Red
        '#a1c57d', -- Green
        '#e6da73', -- Yellow
        '#004aff', -- Blue
        '#d89676', -- Magenta
        '#78bdc5', -- Cyan
        '#cfcec1', -- White
    },
    brights = {
        '#6f6b67', -- Bright Black
        '#f82a71', -- Bright Red
        '#a6e12e', -- Bright Green
        '#ffd866', -- Bright Yellow
        '#ae80fe', -- Bright Blue
        '#fc961f', -- Bright Magenta
        '#63d4ea', -- Bright Cyan
        '#f7f7f1', -- Bright White

    }
}

return {
    -- colors = colors_ansi
    colors = colors_monokai
}