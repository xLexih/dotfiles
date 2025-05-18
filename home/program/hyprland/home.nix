{ config, pkgs, wayland, ... }:

{

  home.packages = with pkgs; [
    wl-clipboard # Clipboard
    kitty # Wayland's default terminal, fall back
    hyprpaper # Wallpaper
    rofi-wayland # Application launcher
    waybar #  Top bar
    gnome-icon-theme # Icon pack for fallback support
    hyprshot # Screenshot tool
    hyprcursor # Cursors for hyprland
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
    # Using this approach, beacuse it lets me "override" default behaviour using "unbind"
    # Using the setting: unbind = [], doesn't work. beacuse order matters!
    extraConfig = builtins.readFile ../../../.config/hypr/hyprland.conf + ''
      $mod = SUPER
      $terminal = alacritty
      env = HYPRCURSOR_THEME,${pkgs.adwaita-icon-theme.name}

      workspace = 1,monitor:HDMI-A-3
      workspace = 2,monitor:HDMI-A-2
      bind = $mod SHIFT, F, exec, firefox
      unbind = $mod, Q                    # unbinds the default terminal keybind
      bind = $mod, Q, exec, alacritty
    '';
    # extraConfig = builtins.readFile ../../../.config/hypr/hyprland.conf;
  };
}
