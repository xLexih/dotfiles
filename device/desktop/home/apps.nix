{pkgs, ...}: {
  home.packages = with pkgs; [
    wl-clipboard
    kitty
    hyprpaper
    rofi-wayland
    waybar
    gnome-icon-theme
  ];
}
