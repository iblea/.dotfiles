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

return {
    window_close_confirmation = "NeverPrompt",
    enable_tab_bar = true,
    scrollback_lines = 35000,
    use_fancy_tab_bar = false,
    window_background_opacity = 0.7,
    -- font = wezterm.font 'WindowsCommandPrompt Nerd Font'

    freetype_load_target = 'HorizontalLcd',
    freetype_render_target = 'HorizontalLcd',

    -- freetype_load_target = 'Normal',
    -- freetype_render_target = 'Normal',

    font_size = 10.0,
    line_height = 1.3,
    cell_width = 0.85,
    underline_thickness = 0,
    underline_position = "-3pt",
    dpi = 140.0,
    -- adjust_window_size_when_changing_font_size = false,
    initial_rows = 35,
    initial_cols = 140,

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

