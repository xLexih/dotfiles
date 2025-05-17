{
  description = "My NixOS configuration with device modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";  # or your preferred nixpkgs version
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";

      # Import your device modules from default.nix logic
      deviceModules = import ./default.nix;

    in
    {
      nixosConfigurations = builtins.listToAttrs (map (deviceName: {
        name = deviceName;
        value = nixpkgs.lib.nixosSystem {
          system = system;
          modules = [ deviceModules.${deviceName} ];
          configuration = {
            # You can add global config here if needed
            nix = {
              settings.experimental-features = [ "nix-command" "flakes" ];
              packageOverrides = self: super: {
                # your package overrides if any
              };
            };
            nixpkgs.config.allowUnfree = true;
            environment.variables.TESTING2 = "updated?";
            system.stateVersion = "24.11";
          };
        };
      }) (builtins.attrNames deviceModules));
    };
}
