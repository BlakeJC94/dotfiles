local wezterm = require("wezterm")
local act = wezterm.action

local appearance = require("appearance")

local config = wezterm.config_builder()

-- Color options
if appearance.is_dark() then
    config.color_scheme = "Gruvbox dark, hard (base16)"
else
    config.color_scheme = "Gruvbox light, hard (base16)"
end

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
}
config.window_close_confirmation = "NeverPrompt"
config.hide_mouse_cursor_when_typing = false

-- Tab bar options
config.enable_tab_bar = true

wezterm.on("update-status", function(window)
    -- Grab the utf8 character for the "powerline" left facing
    -- solid arrow.
    local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

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

wezterm.on("format-tab-title", function(tab)
    local cwd = tab.active_pane.current_working_dir
    if not cwd then
        return tab.tab_title
    end

    local home = os.getenv("HOME") or ""
    local path = cwd.file_path or ""
    local index = tab.tab_index + 1

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

    return index .. " " .. short
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
}

-- Process options
config.skip_close_confirmation_for_processes_named = { "bash", "zsh" }
config.audible_bell = "Disabled"
-- Launch WSL by default when running Wezzterm on windows
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    config.default_domain = "WSL:Ubuntu"
end


return config
