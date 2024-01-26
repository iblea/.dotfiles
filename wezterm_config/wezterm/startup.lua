local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux

wezterm.on('gui-startup', function(cmd)
    -- allow `wezterm start -- something` to affect what we spawn
    -- in our initial window
    -- local args = {}
    -- if cmd then args = cmd.args end

    -- local home = wezterm.home_dir

    -- local stats_tab, stats_pane, window = mux.spawn_window {
    --     workspace = 'default',
    --     cwd = home .. '/.dotfiles'
    -- }
    -- window:gui_window():maximize()
    -- stats_pane:send_text('btop\n')
    -- stats_tab:set_title('stats')

    -- local dotfiles_tab = window:spawn_tab({
    --     args = args,
    --     -- cwd = home .. '/.dotfiles'
    -- })
    -- dotfiles_tab:set_title('dotfiles')
    -- local frontend_tab = window:spawn_tab({cwd = home .. '/me/reporter'})
    -- frontend_tab:set_title('RIP')

    -- window:gui_window():perform_action(act.ActivateTab(0), stats_pane)
end)

local format_title = function(title, is_active, max_width)
    local background = {Background = {Color = '#1f1f28'}}
    local title_len = #title
    local pad_len = math.floor((max_width - title_len) / 2)

    local formatted_title = {
        Text = string.rep(' ', pad_len) .. title .. string.rep(' ', pad_len)
    }
    if is_active then
        return {background, {Foreground = {Color = '#957fb8'}}, formatted_title}
    else
        return {background, {Foreground = {Color = '#cad3f5'}}, formatted_title}
    end
end

local user_var_tab_title_key = 'tab_title';
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    -- if there is title already set, proceed with it
    if type(tab.tab_title) == 'string' and #tab.tab_title > 0 then
        return format_title(tab.tab_title, tab.is_active, max_width)
    end
    return format_title(tab.active_pane.title, tab.is_active, max_width)
    -- return format_title('temp', tab.is_active, max_width)
end)


-- wezterm.on('update-right-status', function(window)
--     local date = wezterm.strftime '%Y-%m-%d %H:%M:%S'
--     window:set_right_status({Foreground = {Color = '#cad3f5'}},
--                             wezterm.format {{Text = ' ' .. date .. ' '}})
-- end)

wezterm.on('user-var-changed', function(window, pane, name, value)
    wezterm.log_info('user-var-changed', name, value)
    if name == user_var_tab_title_key then pane:tab():set_title(value) end
end)



return {}
