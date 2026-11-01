# Notifications (dunst): colors, font and icons in ~/.config/dunst/dunstrc,
# shaped like the rest of the desktop (Hyprland's 10 px rounding and 2 px
# borders, top right inside the screen frame). `dunstctl reload` applies a
# switch to the running daemon, including notifications already on screen.
{pkgs, ...}: {
  modules.theme = {
    render.dunst = theme: let
      c = theme.colors;
      urgency = background: foreground: frame: highlight: timeout: ''
        background = "${background}"
        foreground = "${foreground}"
        frame_color = "${frame}"
        highlight = "${highlight}"
        timeout = ${toString timeout}
      '';
    in {
      ".config/dunst/dunstrc" = ''
        [global]
        follow = keyboard
        origin = top-right
        offset = (12, 12)
        width = (280, 420)
        height = (0, 300)
        notification_limit = 5
        gap_size = 6
        padding = 12
        horizontal_padding = 14
        text_icon_padding = 12
        frame_width = 2
        corner_radius = 10
        separator_height = 2
        separator_color = frame
        layer = overlay

        font = ${theme.fonts.sans}
        markup = full
        format = "<b>%s</b>\n%b"
        alignment = left
        vertical_alignment = center
        ellipsize = middle
        show_age_threshold = 60
        stack_duplicates = true
        hide_duplicate_count = false
        show_indicators = false

        icon_theme = "${theme.icons.name}"
        enable_recursive_icon_lookup = true
        icon_position = left
        min_icon_size = 32
        max_icon_size = 48

        progress_bar_height = 6
        progress_bar_frame_width = 0
        progress_bar_corner_radius = 3

        mouse_left_click = do_action, close_current
        mouse_middle_click = close_all
        mouse_right_click = close_current

        [urgency_low]
        ${urgency c.bg c.fgMuted c.border c.accentAlt 5}
        [urgency_normal]
        ${urgency c.bg c.fg c.accent c.accent 8}
        [urgency_critical]
        ${urgency c.bg c.fg c.red c.red 0}
      '';
    };
    reload.dunst = "${pkgs.dunst}/bin/dunstctl reload";
  };
}
