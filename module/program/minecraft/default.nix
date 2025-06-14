/*
Useful links:
- https://github.com/Diegiwg/PrismLauncher-Cracked/blob/develop/flake.nix
- https://github.com/antunnitraj/Prism-Launcher-PolyMC-Offline-Bypass
*/
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    prismlauncher
  ];
}
/*
echo '{"accounts":[{"profile":{"name":"Premium-Bypass"},"entitlement":{"canPlayMinecraft":true,"ownsMinecraft":true},"msa-client-id":"","type":"MSA"}],"formatVersion":3}' > ~/.local/share/PrismLauncher/accounts.json
*/

