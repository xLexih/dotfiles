{ inputs, config, username, stateVersion, ... }: {
 nixpkgs = {
   overlays = [ inputs.nur.overlay ];
   config = { allowUnfree = true; };
  };
  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    stateVersion = stateVersion;

  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
