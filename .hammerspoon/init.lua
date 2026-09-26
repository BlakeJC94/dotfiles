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

hs.hotkey.bind({"cmd"}, "j", function() focus_app("Ghostty") end)
hs.hotkey.bind({"cmd"}, "h", function() focus_app("Slack") end)
hs.hotkey.bind({"cmd"}, "k", function() focus_app("Firefox") end)

