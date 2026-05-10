{
  lib,
  config,
  pkgs,
  settings,
  ...
}:
let
  cfg = config.program.app.virtual-machine;
in
{
  options.program.app.virtual-machine.enable =
    lib.mkEnableOption "Virtual machine tools (virt-manager)";

  config = lib.mkIf cfg.enable {
    programs.virt-manager.enable = true;
    users.groups.libvirtd.members = settings.users;
    users.users = lib.attrsets.genAttrs settings.users (username: {
      extraGroups = [ "libvirtd" ];
    });
    security.polkit.enable = true;

    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore";
      qemu.runAsRoot = false;
      extraConfig = ''
        unix_sock_group = "libvirtd"
      '';
    };
    virtualisation.spiceUSBRedirection.enable = true;
    services.spice-vdagentd.enable = true;
    environment.systemPackages = with pkgs; [ spice-gtk ];
  };
}
