{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.coding.node;
in
{
  options.coding.node.enable = lib.mkEnableOption "Node.js development tooling" // {
    description = "Installs nodejs_24, npm, yarn, pnpm for JavaScript/TypeScript development.";
  };

  config = lib.mkIf cfg.enable {
  environment.systemPackages = with pkgs; [
    nodejs_25
#    npm
    yarn
    pnpm
  ];
  };
}
