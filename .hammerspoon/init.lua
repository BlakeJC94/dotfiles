local function focus_app(app_name)
    local app = hs.application.get(app_name)
    if app then
        local win = app:mainWindow()
        if win then
            win:focus()
        else
            app:activate()
        end
    else
        hs.application.launchOrFocus(app_name)
    end
end

-- Search across Spaces; Quick Terminal uses AXFloatingWindow, not AXStandardWindow.
local ghostty_windows = hs.window.filter.new(false):setAppFilter("Ghostty", {
    allowRoles = "AXStandardWindow",
})
-- Keep tracking between hotkeys so windows on other Spaces are not forgotten.
ghostty_windows:resume()

hs.hotkey.bind({ "option" }, "j", function()
    local win = ghostty_windows:getWindows(hs.window.filter.sortByFocusedLast)[1]
    if win then
        win:application():unhide()
        win:unminimize()
        win:focus()
    elseif not hs.application.get("Ghostty") then
        hs.application.launchOrFocus("Ghostty")
    else
        hs.alert.show("No normal Ghostty window found")
    end
end)
hs.hotkey.bind({ "option" }, "l", function()
    focus_app("Slack")
end)
hs.hotkey.bind({ "option" }, "k", function()
    focus_app("Firefox")
end)
