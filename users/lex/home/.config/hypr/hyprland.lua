hl.on("hyprland.start", function() hl.exec_cmd("quickshell") end)

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + code:107", hl.dsp.exec_cmd("hyprshot -m region --freeze --clipboard-only"))
hl.bind(mainMod .. " + SHIFT + code:107", hl.dsp.exec_cmd("flameshot gui"))
