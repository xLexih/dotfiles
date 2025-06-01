{ config, pkgs, settings, ... }:

{
  programs.xwayland.enable = true;
  programs.hyprland = {
    enable = true;
#    nvidiaPatches = true;
    xwayland.enable = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };

    # Login Screen
  # services.greetd = {
  #   enable = true;
  #   restart = false;
  #   settings = {
  #     default_session = {
  #       command = "${pkgs.hyprland}/bin/Hyprland";
  #       user = "lex";
  #     };
  #   };
  # };

    environment.systemPackages = with pkgs; [
    neofetch # woo
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
    # egl-wayland # more compatibility stuff
    # libva # hardware acceleration nvidia
    # libva-utils # hardware acceleration nvidia
  ];
# services.xserver = {
#  enable = true;
# };
  # # Cursor theme for X11 and Wayland
  # services.spice-vdagentd.enable = true;

  environment.variables = {
    XDG_SESSION_TYPE = "auto"; # This makes VSCode work (starts with x11 by default yayay)
    ELECTRON_OZONE_PLATFORM_HINT = "auto"; # idk i just want it to be safe will test later
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "16";
    GTK_THEME = "Flat-Remix-GTK-Grey-Darkest";
    GTK_ICON_THEME = "Adwaita";
    GDK_SCALE = "1";
    NIXOS_OZONE_WL = "1";
  };
}
