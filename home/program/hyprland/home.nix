{ config, pkgs, wayland, ... }:

{

  home.packages = with pkgs; [
    wl-clipboard
    kitty
    hyprpaper
    rofi-wayland
    waybar
    gnome-icon-theme
    hyprshot
    alacritty
  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    # hyprcursor.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;

  };

  gtk = {
    enable = true;

    theme = {
      package = pkgs.flat-remix-gtk;
      name = "Flat-Remix-GTK-Grey-Darkest";
    };

    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

    font = {
      name = "Sans";
      size = 11;
    };
  };
  # This is where the configuration is done!! 
  # the settings part is native, the extra config reads the file itself.

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      bind = [ "$mod, F, exec, firefox" ] ++ (
        # workspaces
        # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
        builtins.concatLists (builtins.genList
          (i:
            let ws = i + 1;
            in [
              "$mod, code:1${toString i}, workspace, ${toString ws}"
              "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
            ]
          )
          9)
      );
    };
    extraConfig = builtins.readFile ../../../.config/hypr/hyprland.conf;
  };
}
