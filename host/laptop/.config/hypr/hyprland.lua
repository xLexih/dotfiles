hl.monitor({ output = "eDP-1", mode = "2560x1600@240.00", position = "0x0", scale = 1.33, cm = "auto" })
-- no AQ_DRM_DEVICES: by-path entries contain ':' which Aquamarine treats as a device separator
-- and crashes Hyprland at initServer. Aquamarine auto-detects both GPUs on this hybrid laptop.
hl.config({ misc = { vrr = 1 } })
