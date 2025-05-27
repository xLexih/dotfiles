{ inputs, pkgs, settings, ... }: {
  nixpkgs.config = { allowUnfree = true; };
  environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
  nix = {

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" ] ++ settings.users;
    };
    gc = {
      persistent = true;
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 3d";
    };
  };

}
