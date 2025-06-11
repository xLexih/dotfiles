{
  pkgs,
  config,
  lib,
  ...
}: let
  username = "lex";
  description = "lex here";
in {
  imports = [
    ../module/program/firefox
    ../module/program/ollama
  ];
  ollama.user = username;
  firefox.username = username;

  users.users.${username} = {
    inherit description;

    isNormalUser = true;
    extraGroups = ["docker" "networkmanager" "wheel" "libvirtd" "i2c" "video" "plugdev"];
    packages = with pkgs; [
      btop
      git
      vesktop
      alacritty
      ripgrep
      firefox
      (pkgs.vscodium.overrideAttrs (v_oldAttrs: {
        vscodium = pkgs.vscodium.overrideAttrs (oldAttrs: {
          postInstall = ''
            ${oldAttrs.postInstall or ""}
            ln -sf $out/lib/vscode/bin/codium-tunnel $out/lib/vscode/bin/code-tunnel
          '';
        });
        buildInputs = v_oldAttrs.buildInputs or [] ++ [pkgs.makeWrapper];
        postInstall = ''
          ${v_oldAttrs.postInstall or ""}
          wrapProgram $out/bin/codium --add-flags '--ozone-platform=x11'
        '';
      }))
    ];
  };

  # programs.dconf.enable = true;

  # environment.etc."xdg/gtk-4.0/assets".source = "${pkgs.nordic}/share/themes/Nordic/gtk-4.0/assets";
  # environment.etc."xdg/gtk-4.0/gtk.css".source = "${pkgs.nordic}/share/themes/Nordic/gtk-4.0/gtk.css";
  # environment.etc."xdg/gtk-4.0/gtk-dark.css".source = "${pkgs.nordic}/share/themes/Nordic/gtk-4.0/gtk-dark.css";

  hjem.users.${username} = {
    enable = true;
    user = username;
    directory = config.users.users.${username}.home;
    clobberFiles = lib.mkForce true;
    files = let
      hypr_user_conf = ./${username}/config/hyprland/hyprland.conf;
      hypr_global_conf = ../.config/hypr/hyprland.conf;
      hypr_user_conf_replaced = let
        from = ["{{cursor_theme_name}}"];
        to = [pkgs.adwaita-icon-theme.name];
      in
        lib.mkForce
        (builtins.replaceStrings from to (builtins.readFile hypr_user_conf));
    in {
      ".config/hypr/hyprland.conf".text = builtins.readFile hypr_global_conf + hypr_user_conf_replaced.content;
    };
  };
}
