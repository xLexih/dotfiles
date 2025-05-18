{config, username, stateVersion, ...}: {
  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    stateVersion = stateVersion;
    
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
