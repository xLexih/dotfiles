{ pkgs, ... }: {
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
        # icon fonts
        material-design-icons
        material-symbols
        # normal fonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        noto-fonts-cjk-serif
        dejavu_fonts
        freefont_ttf
        gyre-fonts
        liberation_ttf
        unifont
        noto-fonts-color-emoji
    ];

    # use fonts specified by user rather than default ones
    # enableDefaultPackages = false;
    
    fontconfig.defaultFonts = {
      # serif = [ "Noto Serif" "Noto Color Emoji" ];
      # sansSerif = [ "Noto Sans" "Noto Color Emoji" ];
      # monospace = [ "JetBrainsMono Nerd Font" "Noto Color Emoji" ];
      # emoji = [ "Noto Color Emoji" ];
    };
  };
}
