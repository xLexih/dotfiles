{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.software.virtual-machine;
in {
  options.modules.software.virtual-machine = {
    enable = lib.mkEnableOption "libvirt/QEMU virtual machines";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu.runAsRoot = false;
    };

    programs.virt-manager.enable = true;
    security.polkit.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;

    # The firewall's input chain drops by default, which would also drop the
    # guests' DHCP and DNS requests to libvirt's dnsmasq on the NAT bridge.
    networking.firewall.trustedInterfaces = ["virbr0"];

    environment.systemPackages = with pkgs; [
      spice-gtk # USB redirection support
    ];
  };
}
