for workspace = 1, 9 do hl.workspace_rule({ workspace = tostring(workspace), monitor = "HDMI-A-3" }) end
hl.workspace_rule({ workspace = "0", monitor = "HDMI-A-2" })

hl.monitor({ output = "HDMI-A-3", mode = "1920x1080@144.01", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-2", mode = "1280x1024@75.03", position = "1920x0", scale = 1 })
hl.env("AQ_DRM_DEVICES", "/dev/dri/by-path/pci-0000:16:0:0-card:/dev/dri/by-path/pci-0000:01:00.0-card")
