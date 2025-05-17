let
  # This function takes the path of a device module as an argument
  # and returns a complete module to be imported in configuration.nix
  makeDevice = 
    devicePath:
    { config, pkgs, lib, ... }:

    {
      imports = [
        # ...the device module holding the system configuration...
        devicePath
      ] ++ (import ./module/module-list.nix) lib; # ...and all the extra modules.

#      nixpkgs.config = {
#        packageOverrides = (import ./pkgs/all-packages.nix) lib;
#      };

      nix.nixPath = [
        "nixos-config=/etc/nixos/configuration.nix"
        "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
        "/nix/var/nix/profiles/per-user/root/channels"
      ];
      
      nixpkgs.config.allowUnfree = true;
      environment.variables = {
        TESTING2 = "updated?";
      };


      system.stateVersion = "24.11";

    };
  deviceModules =
    builtins.listToAttrs (map (deviceName: {
      name = deviceName;
      value = makeDevice (./device + "/${deviceName}");
    }) (import ./device/all-devices.nix));
in

deviceModules
