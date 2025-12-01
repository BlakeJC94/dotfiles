local wezterm = require("wezterm")

local p = {}
for line in io.lines(os.getenv("HOME") .. "/.palette") do
    -- ignore empty lines and comment lines
    if not line:match("^%s*#") and line:match("%S") then
        -- match: key="value"
        local key, value = line:match('^%s*([%w_]+)%s*=%s*"(#%x+)"')
        if key and value then
            p[key] = value
        end
    end
end

config = {
    enable_kitty_keyboard = false,
    font = wezterm.font("JetBrainsMono Nerd Font"),
    font_size = 18,
    -- color_scheme = "Gruvbox dark, hard (base16)",
    colors = {
        foreground = p.base05,
        background = p.base00,
        cursor_bg = p.base05,
        ansi = {
            p.base00,
            p.base08,
            p.base0B,
            p.base0A,
            p.base0D,
            p.base0E,
            p.base0C,
            p.base05,
        },
        brights = {
            p.base03,
            p.base08,
            p.base0B,
            p.base0A,
            p.base0D,
            p.base0E,
            p.base0C,
            p.base07,
        },
    },
    -- colors = {
    --     foreground = palette.light1,
    --     background = palette.dark0_hard,
    --     cursor_bg = palette.light1,
    --     cursor_border = palette.light1,
    --     cursor_fg = palette.dark0_hard,
    --     selection_bg = palette.light1,
    --     selection_fg = palette.dark2,
    --     ansi = {
    --         palette.dark0_hard,
    --         palette.neutral_red,
    --         palette.neutral_green,
    --         palette.neutral_yellow,
    --         palette.neutral_blue,
    --         palette.neutral_purple,
    --         palette.neutral_orange,
    --         palette.light4,
    --     },
    --     brights = {
    --         palette.gray,
    --         palette.bright_red,
    --         palette.bright_green,
    --         palette.bright_yellow,
    --         palette.bright_blue,
    --         palette.bright_purple,
    --         palette.bright_orange,
    --         palette.light1,
    --     },
    -- },
    enable_tab_bar = false,
    window_close_confirmation = "NeverPrompt",
    skip_close_confirmation_for_processes_named = { "bash", "zsh" },
    audible_bell = "Disabled",
    disable_default_key_bindings = true,
    keys = {
        { key = "q", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
        { key = "n", mods = "CTRL|SHIFT", action = wezterm.action.SpawnWindow },
        { key = "c", mods = "CTRL|SHIFT", action = { CopyTo = "Clipboard" } },
        { key = "v", mods = "CTRL|SHIFT", action = { PasteFrom = "Clipboard" } },
        { key = "+", mods = "CTRL|SHIFT", action = wezterm.action.IncreaseFontSize },
        { key = "_", mods = "CTRL|SHIFT", action = wezterm.action.DecreaseFontSize },
        { key = "0", mods = "CTRL|SHIFT", action = wezterm.action.ResetFontSize },
        { key = "f", mods = "CTRL|SHIFT", action = wezterm.action.ToggleFullScreen },
    },
    warn_about_missing_glyphs = false,
    hide_mouse_cursor_when_typing = false,
}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    config.default_domain = "WSL:Ubuntu"
end

return config
