hl.env("HYPRCURSOR_THEME", "{{cursor_theme_name}}")
hl.env("XCURSOR_THEME", "{{cursor_theme_name}}")

hl.on("hyprland.start", function() hl.exec_cmd("quickshell") end)

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + code:107", hl.dsp.exec_cmd("hyprshot -m region --freeze --clipboard-only"))
