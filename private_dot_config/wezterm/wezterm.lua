local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- Color options
local is_dark = function()
    if wezterm.gui then
        return wezterm.gui.get_appearance():find("Dark")
    end
    return true
end

if is_dark() then
    config.color_scheme = "Gruvbox dark, hard (base16)"
else
    config.color_scheme = "Gruvbox light, hard (base16)"
end
-- local color_scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]

-- Font options
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 18

-- Window options
config.window_decorations = "RESIZE"
config.window_frame = {
    -- Berkeley Mono for me again, though an idea could be to try a
    -- serif font here instead of monospace for a nicer look?
    font = wezterm.font({ family = "JetBrainsMono Nerd Font", weight = "Medium" }),
    font_size = 16,
    -- The overall background color of the tab bar when
    -- the window is focused
    active_titlebar_bg = "#333333",
    -- The overall background color of the tab bar when
    -- the window is not focused
    inactive_titlebar_bg = "#333333",
}
config.colors = {
    tab_bar = {
        -- The color of the inactive tab bar edge/divider
        inactive_tab_edge = "#333333",
    },
}

config.window_close_confirmation = "NeverPrompt"
config.hide_mouse_cursor_when_typing = false

-- Tab bar options
config.enable_tab_bar = true

wezterm.on("update-status", function(window)
    -- Grab the utf8 character for the "powerline" left facing
    -- solid arrow.
    local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider

    -- Grab the current window's configuration, and from it the
    -- palette (this is the combination of your chosen colour scheme
    -- including any overrides).
    local color_scheme = window:effective_config().resolved_palette
    local bg = color_scheme.background
    local fg = color_scheme.foreground

    window:set_right_status(wezterm.format({
        -- First, we draw the arrow...
        { Background = { Color = "none" } },
        { Foreground = { Color = bg } },
        { Text = SOLID_LEFT_ARROW },
        -- Then we draw our text
        { Background = { Color = bg } },
        { Foreground = { Color = fg } },
        { Text = " " .. wezterm.strftime("%a %b %-d | %H:%M") .. " " },
    }))
end)

-- This function returns the suggested title for a tab.
local tab_title = function(tab)
    local cwd = tab.active_pane.current_working_dir
    if not cwd then
        return tab.tab_title
    end

    local home = os.getenv("HOME") or ""
    local path = cwd.file_path or ""

    -- Replace home with ~
    if home ~= "" and path:sub(1, #home) == home then
        path = "~" .. path:sub(#home + 1)
    end

    -- Split safely
    local parts = {}
    for piece in string.gmatch(path, "[^/]+") do
        table.insert(parts, piece)
    end

    -- Get last three parts
    local count = #parts
    local start = math.max(1, count - 2)
    local short = table.concat({ table.unpack(parts, start, count) }, "/")

    return short
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local index = tab.tab_index + 1
    local short = tab_title(tab)
    local title = " " .. index .. ": " .. short .. " "

    local color_scheme = config.resolved_palette
    local bg = color_scheme.background
    local fg = color_scheme.foreground

    if tab.is_active then
        return {
            { Background = { Color = bg } },
            { Foreground = { Color = fg } },
            { Text = title },
        }
    end
    return title
end)

-- Keybindings
config.disable_default_key_bindings = true

config.leader = { key = "z", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
    {
        key = "z",
        -- When we're in leader mode _and_ CTRL + A is pressed...
        mods = "LEADER|CTRL",
        -- Actually send CTRL + A key to the terminal
        action = act.SendKey({ key = "z", mods = "CTRL" }),
    },
    { key = "q", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
    { key = "n", mods = "CTRL|SHIFT", action = act.SpawnWindow },
    { key = "c", mods = "CTRL|SHIFT", action = { CopyTo = "Clipboard" } },
    { key = "v", mods = "CTRL|SHIFT", action = { PasteFrom = "Clipboard" } },
    { key = "+", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
    { key = "_", mods = "CTRL|SHIFT", action = act.DecreaseFontSize },
    { key = "0", mods = "CTRL|SHIFT", action = act.ResetFontSize },
    { key = "f", mods = "CTRL|SHIFT", action = act.ToggleFullScreen },
    { key = "l", mods = "CTRL|SHIFT", action = act.ShowDebugOverlay },
    {
        key = "p",
        mods = "CTRL|SHIFT",
        action = wezterm.action.ActivateCommandPalette,
    },
    -- Leader keys
    {
        key = "s",
        mods = "LEADER",
        action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
    },
    {
        key = "v",
        mods = "LEADER",
        action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
    },
    {
        key = "Space",
        mods = "LEADER",
        action = act.ActivateCopyMode,
    },
    {
        key = "q",
        mods = "LEADER",
        action = wezterm.action.CloseCurrentPane({ confirm = false }),
    },
    {
        key = "o",
        mods = "LEADER",
        action = wezterm.action.TogglePaneZoomState,
    },
    {
        key = "/",
        mods = "LEADER",
        action = wezterm.action.QuickSelect,
    },
    {
        key = "c",
        mods = "LEADER",
        action = act.SpawnTab("CurrentPaneDomain"),
    },
    { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
    { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
    { key = "P", mods = "LEADER", action = act.MoveTabRelative(-1) },
    { key = "N", mods = "LEADER", action = act.MoveTabRelative(1) },
    {
        key = "Q",
        mods = "LEADER",
        action = act.CloseCurrentTab({ confirm = true }),
    },
    {
        key = "u",
        mods = "SHIFT|CTRL",
        action = wezterm.action.CharSelect({
            copy_on_select = true,
            copy_to = "ClipboardAndPrimarySelection",
        }),
    },
    --
    {
        key = "LeftArrow",
        mods = "LEADER",
        action = act.ActivatePaneDirection("Left"),
    },
    {
        key = "RightArrow",
        mods = "LEADER",
        action = act.ActivatePaneDirection("Right"),
    },
    {
        key = "UpArrow",
        mods = "LEADER",
        action = act.ActivatePaneDirection("Up"),
    },
    {
        key = "DownArrow",
        mods = "LEADER",
        action = act.ActivatePaneDirection("Down"),
    },
    {
        key = "h",
        mods = "LEADER",
        action = act.ActivatePaneDirection("Left"),
    },
    {
        key = "l",
        mods = "LEADER",
        action = act.ActivatePaneDirection("Right"),
    },
    {
        key = "k",
        mods = "LEADER",
        action = act.ActivatePaneDirection("Up"),
    },
    {
        key = "j",
        mods = "LEADER",
        action = act.ActivatePaneDirection("Down"),
    },
    {
        key = "h",
        mods = "ALT",
        action = act.AdjustPaneSize({ "Left", 5 }),
    },
    {
        key = "j",
        mods = "ALT",
        action = act.AdjustPaneSize({ "Down", 5 }),
    },
    {
        key = "k",
        mods = "ALT",
        action = act.AdjustPaneSize({ "Up", 5 }),
    },
    {
        key = "l",
        mods = "ALT",
        action = act.AdjustPaneSize({ "Right", 5 }),
    },
    {
        key = "LeftArrow",
        mods = "ALT",
        action = act.AdjustPaneSize({ "Left", 5 }),
    },
    {
        key = "DownArrow",
        mods = "ALT",
        action = act.AdjustPaneSize({ "Down", 5 }),
    },
    {
        key = "UpArrow",
        mods = "ALT",
        action = act.AdjustPaneSize({ "Up", 5 }),
    },
    {
        key = "RightArrow",
        mods = "ALT",
        action = act.AdjustPaneSize({ "Right", 5 }),
    },
    {
        key = "/",
        mods = "LEADER",
        action = act.Search({ CaseInSensitiveString = "" }),
    },
    {
        key = "0",
        mods = "LEADER",
        action = act.ActivateTab(0),
    },
    {
        key = "Tab",
        mods = "LEADER",
        action = act.ActivateLastTab,
    },
}

for i = 1, 9 do
    table.insert(config.keys, {
        key = tostring(i),
        mods = "LEADER",
        action = act.ActivateTab(i - 1),
    })
end

-- Process options
config.skip_close_confirmation_for_processes_named = { "bash", "zsh" }
config.audible_bell = "Disabled"

-- Launch WSL by default when running Wezterm on windows
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    -- config.default_domain = "WSL:Ubuntu"
    config.default_prog = { "wsl.exe", "-d", "Ubuntu", "--cd", "~" }
end

return config
