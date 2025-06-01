{ config, lib, options,  pkgs, settings, ... }:

{
  boot.kernelParams = [ 
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];
  programs.xwayland.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;

  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };
  
  environment.systemPackages = with pkgs; [
    egl-wayland # more compatibility stuff
    
    wl-clipboard # Clipboard
    kitty # Wayland's default terminal, fall back
    hyprpaper # Wallpaper
    rofi-wayland # Application launcher
    waybar # Top bar
    gnome-icon-theme # Icon pack for fallback support
    hyprshot # Screenshot tool
    hyprcursor # Cursors for hyprland
    
    # Themes raaa
    gtk4
    nwg-look
    bibata-cursors
    adwaita-icon-theme
    nordic
  ];

  environment.variables = {
    ELECTRON_OZONE_PLATFORM_HINT = "auto"; # idk i just want it to be safe will test later
    GTK_USE_PORTAL = "1";
    NIXOS_XDG_OPEN_USE_PORTAL = "1";
    NIXOS_OZONE_WL = "1";
    
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
    MOZ_ENABLE_WAYLAND = "1";
#    GDK_BACKEND = "wayland";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "16";
    GTK_THEME = "Flat-Remix-GTK-Grey-Darkest";
    GTK_ICON_THEME = "Adwaita";
    GDK_SCALE = "1";
  };
}
