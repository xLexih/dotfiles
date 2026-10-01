-- Monitors are matched by description: their connector names change with the
-- port they're plugged into.
local asus = "desc:ASUSTek COMPUTER INC ASUS VG249 0x0003B507"
local philips = "desc:Philips Consumer Electronics Company Philips 190C BZ30728221667"

for workspace = 1, 9 do hl.workspace_rule({ workspace = tostring(workspace), monitor = asus }) end
hl.workspace_rule({ workspace = "10", monitor = philips })

hl.monitor({ output = asus, mode = "1920x1080@144.01", position = "0x0", scale = 1 })
hl.monitor({ output = philips, mode = "1280x1024@75.03", position = "1920x0", scale = 1 })
