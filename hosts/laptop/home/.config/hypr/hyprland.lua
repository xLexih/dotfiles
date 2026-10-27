hl.monitor({ output = "eDP-1", mode = "2560x1600@240.00", position = "0x0", scale = 1.33, cm = "auto" })
-- no AQ_DRM_DEVICES: by-path entries contain ':' which Aquamarine treats as a device separator
-- and crashes Hyprland at initServer. Aquamarine auto-detects both GPUs on this hybrid laptop.
hl.config({ misc = { vrr = 1 } })
-- logind ignores the lid (hosts/laptop/power.nix): closing it only turns the panel off.
hl.bind("switch:on:Lid Switch", hl.dsp.dpms({ monitor = "eDP-1", action = "off" }), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.dpms({ monitor = "eDP-1", action = "on" }), { locked = true })
