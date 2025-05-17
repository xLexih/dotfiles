{ config, pkgs, ...}:

{
  programs.xwayland.enable = true;  
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs.hyprland;
  };
  environment.systemPackages = with pkgs; [ 
    wl-clipboard
    kitty
    hyprpaper
    rofi-wayland
    waybar
    gnome-icon-theme
  ];

  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
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

  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";
    bind = ["$mod, F, exec, firefox"];
#    bind =
#      [
#        "$mod, F, exec, firefox"
#        ", Print, exec, grimblast copy area"
#      ]
#      ++ (
#        # workspaces
#        # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
#        builtins.concatLists (builtins.genList (i:
#            let ws = i + 1;
#            in [
#              "$mod, code:1${toString i}, workspace, ${toString ws}"
#              "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
#            ]
#          )
#          9)
#      );
  };

}
