hl.on("hyprland.start", function()
    -- Export the Wayland session before launching desktop services.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE; noctalia")
    -- Use Waybar as the sole panel; Noctalia remains active for its other services.
    hl.exec_cmd("waybar")
end)
