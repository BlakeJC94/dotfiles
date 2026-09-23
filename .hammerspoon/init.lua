local launch_app = function(app_name)
    local app = hs.application.get(app_name)
    if app then
        app:activate()
    else
        hs.application.launchOrFocus(app_name)
    end
end

hs.hotkey.bind({"cmd"}, "j", function()
    launch_app("Ghostty")
end)

hs.hotkey.bind({"cmd"}, "h", function()
    launch_app("Slack")
end)

hs.hotkey.bind({"cmd"}, "k", function()
    launch_app("Firefox")
end)
