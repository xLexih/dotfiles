local terminal = "kitty"
local fileManager = "nautilus"
local menu = "rofi -show drun"
local mainMod = "SUPER"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.env("XCURSOR_SIZE", "{{cursor_size}}")
hl.env("HYPRCURSOR_SIZE", "{{cursor_size}}")
hl.env("QT_QPA_PLATFORMTHEME", "{{qt_platform_theme}}")
hl.env("QT_STYLE_OVERRIDE", "{{qt_style}}")
hl.env("XDG_SESSION_TYPE", "wayland")

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user start hyprland-session.target")
end)
hl.on("hyprland.shutdown", function() hl.exec_cmd("systemctl --user stop hyprland-session.target") end)

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 3,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba({{ui_accent_hex}}ee)", "rgba({{ui_accent_bright_hex}}ee)" }, angle = 45 },
            inactive_border = "rgba({{ui_overlay_hex}}aa)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = true, range = 4, render_power = 3, color = "rgba({{ui_shadow_hex}}ee)" },
        blur = { enabled = true, size = 3, passes = 1, vibrancy = 0.1696 },
    },
    animations = { enabled = true },
    dwindle = {
        force_split = 0,
        preserve_split = true,
        smart_split = false,
        smart_resizing = true,
        permanent_direction_override = false,
        special_scale_factor = 0.933333,
        split_width_multiplier = 1.0,
        use_active_for_splits = true,
        default_split_ratio = 1.0,
    },
    misc = {
        vrr = 2,
        on_focus_under_fullscreen = 1,
        focus_on_activate = true,
        force_default_wallpaper = -1,
    },
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        numlock_by_default = true,
        touchpad = { disable_while_typing = false, natural_scroll = false },
    },
    gestures = {
        workspace_swipe_distance = 400,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_forever = true,
    },
    xwayland = { use_nearest_neighbor = true, force_zero_scaling = true },
})

local curves = {
    { "easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } } },
    { "easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } } },
    { "linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } } },
    { "almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } } },
    { "quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } } },
}
for _, curve in ipairs(curves) do hl.curve(curve[1], curve[2]) end

local animations = {
    { leaf = "global", enabled = true, speed = 10, bezier = "default" },
    { leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" },
    { leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" },
    { leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" },
    { leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" },
    { leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" },
    { leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" },
    { leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" },
    { leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" },
    { leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" },
    { leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" },
    { leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" },
    { leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" },
    { leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" },
    { leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" },
    { leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" },
}
for _, animation in ipairs(animations) do hl.animation(animation) end

hl.window_rule({ name = "alacritty-kitty-scroll", match = { class = "(Alacritty|kitty)" }, scroll_touchpad = 1.5 })
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
hl.window_rule({ name = "intellij-main", match = { class = "^(jetbrains-idea-ce)$", title = "negative:^win.*$" }, float = false })
hl.window_rule({
    name = "intellij-popups",
    match = { class = "^(jetbrains-idea-ce)$", title = "^win.*$" },
    no_focus = true,
    no_initial_focus = true,
    float = true,
    no_blur = true,
    no_shadow = true,
})
hl.window_rule({ name = "intellij-stayfocused", match = { class = "^(jetbrains-idea-ce)$", title = "negative:^win.*$" }, stay_focused = true })
hl.window_rule({ name = "jetbrains-all", match = { class = "(jetbrains-.*)" }, no_anim = true, no_initial_focus = true })
hl.window_rule({ name = "quickshell-notes", match = { title = "^Notes$" }, float = true, size = { 320, 400 }, center = true })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

local function bind(keys, dispatcher, flags) hl.bind(mainMod .. " + " .. keys, dispatcher, flags) end
bind("Q", hl.dsp.exec_cmd(terminal))
bind("C", hl.dsp.window.close())
bind("M", hl.dsp.exit())
bind("E", hl.dsp.exec_cmd(fileManager))
bind("V", hl.dsp.window.float())
bind("R", hl.dsp.exec_cmd(menu))
bind("P", hl.dsp.window.pseudo())
bind("D", hl.dsp.layout("togglesplit"))

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    bind(direction, hl.dsp.focus({ direction = direction }))
    bind("SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }))
end
bind("Tab", hl.dsp.window.cycle_next())
hl.bind("CTRL + ALT + left", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + ALT + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("CTRL + ALT + SHIFT + left", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind("CTRL + ALT + SHIFT + right", hl.dsp.window.move({ workspace = "e+1" }))
bind("S", hl.dsp.workspace.toggle_special("magic"))
bind("SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

local keypad = { "KP_End", "KP_Down", "KP_Next", "KP_Left", "KP_Begin", "KP_Right", "KP_Home", "KP_Up", "KP_Prior", "KP_Insert" }
for workspace = 1, 10 do
    local key = workspace % 10
    bind(tostring(key), hl.dsp.focus({ workspace = workspace }))
    bind("SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
    bind(keypad[workspace], hl.dsp.focus({ workspace = workspace }))
    bind("SHIFT + " .. keypad[workspace], hl.dsp.window.move({ workspace = workspace }))
end

bind("ALT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
bind("ALT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
bind("ALT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
bind("ALT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))
bind("mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind("mouse_up", hl.dsp.focus({ workspace = "e-1" }))
bind("mouse:272", hl.dsp.window.drag(), { mouse = true })
bind("mouse:273", hl.dsp.window.resize(), { mouse = true })

local mediaBinds = {
    { "XF86AudioRaiseVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+", { locked = true, repeating = true } },
    { "XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", { locked = true, repeating = true } },
    { "XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true, repeating = true } },
    { "XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", { locked = true, repeating = true } },
    { "XF86MonBrightnessUp", "brightnessctl s 10%+", { locked = true, repeating = true } },
    { "XF86MonBrightnessDown", "brightnessctl s 10%-", { locked = true, repeating = true } },
    { "XF86AudioNext", "playerctl next", { locked = true } },
    { "XF86AudioPause", "playerctl play-pause", { locked = true } },
    { "XF86AudioPlay", "playerctl play-pause", { locked = true } },
    { "XF86AudioPrev", "playerctl previous", { locked = true } },
}
for _, mediaBind in ipairs(mediaBinds) do hl.bind(mediaBind[1], hl.dsp.exec_cmd(mediaBind[2]), mediaBind[3]) end

bind("F", hl.dsp.window.fullscreen())
bind("Space", hl.dsp.window.float())
bind("Space", hl.dsp.window.center())
