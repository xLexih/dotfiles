{
  lib,
  inputs,
  settings,
  ...
}: {
  environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
  nixpkgs.hostPlatform = lib.mkDefault settings.system;
  nix = {
    settings = {
      download-buffer-size = 524288000; # https://github.com/NixOS/nix/issues/11728#issuecomment-2725297584
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      trusted-users = ["root"] ++ settings.users;
    };
    gc = {
      persistent = true;
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 3d";
    };
  };
}
