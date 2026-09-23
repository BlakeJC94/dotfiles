local launch_app = function(app_name)
    hs.application.launchOrFocus(app_name)
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
