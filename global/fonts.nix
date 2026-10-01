{pkgs, ...}: {
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      dejavu_fonts
      freefont_ttf
      gyre-fonts
      jetbrains-mono
      liberation_ttf
      material-design-icons
      material-symbols
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.iosevka
      nerd-fonts.jetbrains-mono
      nerd-fonts.meslo-lg
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      unifont
    ];
    fontconfig.defaultFonts = {
      serif = ["Noto Serif" "Noto Color Emoji"];
      sansSerif = ["Noto Sans" "Noto Color Emoji"];
      monospace = ["JetBrains Mono" "Noto Color Emoji"];
      emoji = ["Noto Color Emoji"];
    };
  };
}
