{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    alejandra # nix
    direnv # nix
    nix-tree # nix
    nil # nix
    nixd # nix
    fzf # i need it.
  ];
}
