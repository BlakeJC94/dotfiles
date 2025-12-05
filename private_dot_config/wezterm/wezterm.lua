local wezterm = require("wezterm")
local act = wezterm.action

config = {
    enable_kitty_keyboard = false,
    font = wezterm.font("JetBrainsMono Nerd Font"),
    font_size = 18,
    color_scheme = "Gruvbox dark, hard (base16)",
    enable_tab_bar = true,
    window_close_confirmation = "NeverPrompt",
    skip_close_confirmation_for_processes_named = { "bash", "zsh" },
    audible_bell = "Disabled",
    disable_default_key_bindings = true,
    leader = { key = "z", mods = "CTRL", timeout_milliseconds = 1000 },
    keys = {
        { key = "q", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
        { key = "n", mods = "CTRL|SHIFT", action = act.SpawnWindow },
        { key = "c", mods = "CTRL|SHIFT", action = { CopyTo = "Clipboard" } },
        { key = "v", mods = "CTRL|SHIFT", action = { PasteFrom = "Clipboard" } },
        { key = "+", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
        { key = "_", mods = "CTRL|SHIFT", action = act.DecreaseFontSize },
        { key = "0", mods = "CTRL|SHIFT", action = act.ResetFontSize },
        { key = "f", mods = "CTRL|SHIFT", action = act.ToggleFullScreen },
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
            action = wezterm.action.CloseCurrentTab({ confirm = true }),
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
            key = "/",
            mods = "LEADER",
            action = act.Search({ CaseInSensitiveString = "" }),
        },
    },
    warn_about_missing_glyphs = false,
    hide_mouse_cursor_when_typing = false,
}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    config.default_domain = "WSL:Ubuntu"
end

return config
