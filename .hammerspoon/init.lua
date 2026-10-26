local filters = {}

local function bind_app(key, app_name)
    local windows = hs.window.filter.new(false):setAppFilter(app_name, {
        allowRoles = app_name == "Ghostty"
            and { "AXStandardWindow", "AXFullScreenWindow" }
            or "AXStandardWindow",
    })
    windows:resume()
    filters[app_name] = windows

    hs.hotkey.bind({ "option" }, key, function()
        local matches = windows:getWindows(hs.window.filter.sortByFocusedLast)
        local target

        if app_name == "Ghostty" then
            local slack_spaces = {}

            for _, win in ipairs(filters.Slack:getWindows()) do
                for _, space in ipairs(hs.spaces.windowSpaces(win:id()) or {}) do
                    slack_spaces[space] = true
                end
            end

            for _, win in ipairs(matches) do
                local spaces = hs.spaces.windowSpaces(win:id()) or {}
                local separate = #spaces > 0

                for _, space in ipairs(spaces) do
                    if slack_spaces[space] then
                        separate = false
                        break
                    end
                end

                if separate and win:subrole() ~= "AXFloatingWindow" then
                    target = win
                    break
                end
            end
        else
            target = matches[1]
            for _, win in ipairs(matches) do
                if win:isFullScreen() then
                    target = win
                    break
                end
            end
        end

        if target then
            target:application():unhide()
            target:unminimize()
            target:focus()
        elseif not hs.application.get(app_name) then
            hs.application.launchOrFocus(app_name)
        else
            hs.alert.show("No matching " .. app_name .. " window found")
        end
    end)
end

bind_app("h", "Slack")
bind_app("j", "Ghostty")
bind_app("k", "Firefox")

hs.hotkey.bind({ "option" }, "l", function()
    local spaces = hs.spaces.spacesForScreen(hs.screen.mainScreen()) or {}

    for _, space in ipairs(spaces) do
        if hs.spaces.spaceType(space) == "user" then
            hs.spaces.gotoSpace(space)
            return
        end
    end
end)

