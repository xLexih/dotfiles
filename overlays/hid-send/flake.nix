{
  description = "A tool to send HID feature reports to a specific device";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems (system: let pkgs = nixpkgsFor.${system}; in {
        hid-send = pkgs.stdenv.mkDerivation {
          pname = "hid-send";
          version = "0.0.1";
          src = ./.;
          nativeBuildInputs = [ pkgs.gcc ];
          buildPhase = ''
            g++ hid_send.cpp -o hid-send
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp hid-send $out/bin/
          '';
        };
        default = self.packages.${system}.hid-send;
      });

      apps = forAllSystems (system: let pkgs = nixpkgsFor.${system}; in {
        enable = {
          type = "app";
          program = toString (pkgs.writeShellScript "enable-hid" ''
            sudo ${self.packages.${system}.hid-send}/bin/hid-send /dev/hidraw2 00:01:ff:ff:ff:ff:00:00:00:00:00:00:00:00:00:00:00
          '');
        };
        disable = {
          type = "app";
          program = toString (pkgs.writeShellScript "disable-hid" ''
            sudo ${self.packages.${system}.hid-send}/bin/hid-send /dev/hidraw2 01:ff:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
          '');
        };
      });
    };
}
