hs.hotkey.bind({"cmd"}, "j", function()
    local app = hs.application.get("Ghostty")
    if app then
        app:activate()
    else
        hs.application.launchOrFocus("Ghostty")
    end
end)
