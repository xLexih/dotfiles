hl.monitor({ output = "eDP-1", mode = "2560x1600@240.00", position = "0x0", scale = 1.33, cm = "auto" })
-- by-path: cardN minors shift across boots and silently break screencopy DMA. iGPU first for battery.
hl.env("AQ_DRM_DEVICES", "/dev/dri/by-path/pci-0000:00:02.0-card:/dev/dri/by-path/pci-0000:01:00.0-card")
hl.env("XCURSOR_SIZE", "21")
hl.env("HYPRCURSOR_SIZE", "21")
hl.config({ misc = { vrr = 1 } })
