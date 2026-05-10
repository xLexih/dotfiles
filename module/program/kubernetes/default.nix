{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.program.app.kubernetes;
in
{
  options.program.app.kubernetes.enable =
    lib.mkEnableOption "Kubernetes tools (kubectl, helm, k9s, etc.)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      k9s
      kubectl
      kubernetes-helm
      cilium-cli
      mirrord
      devspace
    ];
  };
}
