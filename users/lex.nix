{ pkgs, config, inputs, lib, ... }:
let
  username = "lex";
  description = "lex here";
  hostname = config.networking.hostName;
in {
  users.users.${username} = {
    inherit description;

    isNormalUser = true;
    extraGroups = [  "docker" "networkmanager" "wheel" "libvirtd" "i2c" "video" "plugdev"];
    packages = with pkgs; [ 
      btop 
      git
      vesktop
      alacritty
      ripgrep
      firefox
      (vscodium-fhs.overrideAttrs {
        vscodium = pkgs.vscodium.overrideAttrs (oldAttrs:{
        postInstall = ''
            ${oldAttrs.postInstall or ""}
            ls -l $out/lib/vscode/bin || true
            ln -sf $out/lib/vscode/bin/codium-tunnel $out/lib/vscode/bin/code-tunnel
          '';
        });
      })];
  };

  hjem.users.${username} = {
    enable = true;
    user = username;
    directory = config.users.users.${username}.home;
    clobberFiles = lib.mkForce true;
    files = let
      hypr_user_conf = ./${username}/config/hyprland/hyprland.conf;
      hypr_global_conf = ../.config/hypr/hyprland.conf;
      hypr_user_conf_replaced = let
        from = [ "{{cursor_theme_name}}" ];
        to = [ pkgs.adwaita-icon-theme.name ];
      in lib.mkForce
      (builtins.replaceStrings from to (builtins.readFile hypr_user_conf));
    in {
  ".config/hypr/hyprland.conf".text = builtins.readFile hypr_global_conf + hypr_user_conf_replaced.content;
    };
  };
}
