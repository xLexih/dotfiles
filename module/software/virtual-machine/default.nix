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

    services.spice-vdagentd.enable = true;

    environment.systemPackages = with pkgs; [
      spice-gtk # USB redirection support
    ];
  };
}
