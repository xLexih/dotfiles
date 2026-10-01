{
  config,
  pkgs,
  ...
}: {
  users.users.lex = {
    isNormalUser = true;
    extraGroups = ["wheel" "video" "audio" "networkmanager" "docker" "libvirtd" "i2c" "plugdev"];
  };

  # `nh os switch` and friends work from any directory.
  programs.nh = {
    enable = true;
    flake = "${config.users.users.lex.home}/dotfiles";
  };

  fonts.packages = [pkgs.corefonts];

  modules.software = {
    docker = {
      enable = true;
      nvidia.enable = true;
    };
    gaming.enable = true;
    kdeconnect.enable = true;
    obs.enable = true;
    sunshine.enable = true;
    virtual-machine.enable = true;
    waydroid.enable = true;
  };

  hjem.users.lex.files.".local/share/lutris/runners/proton/GE-Proton".source = pkgs.proton-ge-bin.steamcompattool;
}
