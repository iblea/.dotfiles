local wezterm = require 'wezterm'
local act = wezterm.action

return {
    disable_default_key_bindings = true,
    -- https://wezfurlong.org/wezterm/config/lua/keyassignment/index.html
    keys = {
        -- {
        --     key = '-',
        --     mods = 'LEADER',
        --     action = act.SplitVertical({domain = 'CurrentPaneDomain'})
        -- },
        { key = 'c', mods = 'SUPER', action = wezterm.action.CopyTo 'ClipboardAndPrimarySelection',},
        { key = 'd', mods = 'SUPER', action = act.PasteFrom 'Clipboard' },
        {
            key = 'r',
            mods = 'SHIFT|SUPER',
            action = wezterm.action.ReloadConfiguration,
        },
        {
            key = 'y',
            mods = 'SUPER',
            action = wezterm.action.SpawnCommandInNewTab {
                args = { 'top' },
            },
        },
        {
            key = 'y',
            mods = 'SUPER|SHIFT',
            action = wezterm.action.SpawnCommandInNewWindow {
                args = { 'top' },
            },
        },
        -- {
        --     key = 'y',
        --     mods = 'CTRL|SUPER',
        --     action = wezterm.action.SplitPane {
        --         direction = 'RIGHT',
        --         command = { args = { 'top' } },
        --         size = { Percent = 50 },
        --     },
        -- },
        -- {
        --     key = 'y',
        --     mods = 'CTRL|SUPER',
        --     action = wezterm.action.SplitHorizontal {
        --         args = { 'top' },
        --     },
        -- },



        { key = 't', mods = 'SUPER', action = act.SpawnTab 'DefaultDomain' },
        { key = 'n', mods = 'SUPER', action = wezterm.action.SpawnWindow },

        { key = 'q', mods = 'SUPER', action = wezterm.action.QuitApplication },
        { key = 'w', mods = 'SUPER', action = wezterm.action.CloseCurrentPane { confirm = false }, },
        {
            key = 'p',
            mods = 'SUPER',
            action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
        },
        {
            key = 'u',
            mods = 'SUPER',
            action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
        },

        { key = 'h', mods = 'SUPER', action = act.ActivatePaneDirection 'Prev', },
        { key = 'l', mods = 'SUPER', action = act.ActivatePaneDirection 'Next', },
        { key = 'j', mods = 'SUPER', action = act.MoveTabRelative(-1) },
        { key = 'k', mods = 'SUPER', action = act.MoveTabRelative(1) },
        { key = 'm', mods = 'SUPER', action = act.PaneSelect, },


        { key = 'PageUp', mods = 'SHIFT', action = act.ScrollByPage(-1) },
        { key = 'PageDown', mods = 'SHIFT', action = act.ScrollByPage(1) },
        { key = 'UpArrow', mods = 'SHIFT', action = act.ScrollByLine(-1) },
        { key = 'DownArrow', mods = 'SHIFT', action = act.ScrollByLine(1) },
        { key = 'i', mods = 'CTRL|SUPER', action = act.ScrollByPage(-1) },
        { key = 'o', mods = 'CTRL|SUPER', action = act.ScrollByPage(1) },
        { key = 'i', mods = 'SUPER', action = act.ScrollByPage(-0.5) },
        { key = 'o', mods = 'SUPER', action = act.ScrollByPage(0.5) },
        { key = 'i', mods = 'SHIFT|SUPER', action = act.ScrollByLine(-1) },
        { key = 'o', mods = 'SHIFT|SUPER', action = act.ScrollByLine(1) },

    }
}
