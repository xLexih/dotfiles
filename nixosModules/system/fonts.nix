{ pkgs, ... }: {
  fonts = {
    fontDir.enable = true;
    packages = let
      caskydia = with pkgs.nerd-fonts; [ caskaydia-mono caskaydia-cove ];

      noto = with pkgs; [
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
    in caskydia ++ noto;

    # use fonts specified by user rather than default ones
    # enableDefaultPackages = false;

    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    fontconfig.defaultFonts = {
      # serif = [ "Noto Serif" "Noto Color Emoji" ];
      # sansSerif = [ "Noto Sans" "Noto Color Emoji" ];
      # monospace = [ "JetBrainsMono Nerd Font" "Noto Color Emoji" ];
      # emoji = [ "Noto Color Emoji" ];
    };
  };
}
