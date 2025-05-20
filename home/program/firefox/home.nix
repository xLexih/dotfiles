{ pkgs, username, ... }: {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    profiles.default = {
      id = 0;
      name = username;
      isDefault = true;
      # extensions = with pkgs.nur.repos.rycee.firefox-addons; [ 
      #   ublock-origin
      # ];
    };
  };
}
