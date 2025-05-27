{ config, pkgs, settings, ... }:

{
  programs.xwayland.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true; 
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };

  environment.systemPackages = with pkgs; [
    wl-clipboard # Clipboard
    kitty # Wayland's default terminal, fall back
    hyprpaper # Wallpaper
    rofi-wayland # Application launcher
    waybar # Top bar
    gnome-icon-theme # Icon pack for fallback support
    hyprshot # Screenshot tool
    hyprcursor # Cursors for hyprland
    # nvidia-utils # support for nvidia
    # lib32-nvidia-utils # game support for more specific wine stuff
    egl-wayland # more compatibility stuff
    libva # hardware acceleration nvidia
    libva-utils # hardware acceleration nvidia
  ];

  # # Cursor theme for X11 and Wayland
  # services.xserver = {
  #   enable = true;
  #   # Might replace with greetd (with ReGreet), looking into UWSM.
  #   # displayManager.sddm.wayland.enable = true;

  #   displayManager.sessionCommands = ''
  #     # Set cursor theme for X11
  #     xsetroot -cursor_name left_ptr
  #     export XCURSOR_THEME=Bibata-Modern-Classic
  #     export XCURSOR_SIZE=16
  #   '';
  #   # desktopManager.default = "none"; # if you don't use X11 desktop manager
  # };

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "16";
    GTK_THEME = "Flat-Remix-GTK-Grey-Darkest";
    GTK_ICON_THEME = "Adwaita";
    GDK_SCALE = "1";
    NIXOS_OZONE_WL = "1";
  };
}
