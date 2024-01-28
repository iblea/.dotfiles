local wezterm = require 'wezterm'

local wezterm_font_config = wezterm.font_with_fallback {
    {
        italic = false,
        family = 'WindowsCommandPrompt Nerd Font',
        -- family = 'BigBlueTermPlus Nerd Font',
        weight = 'Regular',
        stretch = 'Expanded',
        harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
    },
    {
        italic = false,
        family = '둥근모꼴',
        -- family = 'BigBlueTermPlus Nerd Font',
        weight = 'Light',
        harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
    },
}

-- https://github.com/wez/wezterm/issues/4096

return {
    window_close_confirmation = "NeverPrompt",
    window_background_opacity = 1.0,
    enable_tab_bar = true,
    scrollback_lines = 35000,
    use_fancy_tab_bar = false,
    -- font = wezterm.font 'WindowsCommandPrompt Nerd Font'

    freetype_load_target = 'HorizontalLcd',
    freetype_render_target = 'HorizontalLcd',

    -- freetype_load_target = 'Normal',
    -- freetype_render_target = 'Normal',

    -- dpi = 144.0,
    -- dpi = 72.0,
    -- -- 1920x1080 144hz
    -- font_size = 10.0,
    -- initial_cols = 140,
    -- initial_rows = 35,
    -- -- 2560x1440 144hz
    font_size = 19.0,
    initial_cols = 110,
    initial_rows = 30,
    line_height = 1.3,
    cell_width = 0.85,
    underline_thickness = 0,
    underline_position = "-3pt",
    -- adjust_window_size_when_changing_font_size = false,

    font = wezterm_font_config,
    font_rules = {
        {
            intensity = 'Bold',
            italic = false,
            font = wezterm_font_config,
        },
        {
            intensity = 'Bold',
            italic = true,
            font = wezterm_font_config,
        }

    },
}

