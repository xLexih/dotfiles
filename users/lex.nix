{
  pkgs,
  config,
  lib,
  settings,
  ...
}: let
  username = "lex";
  description = "lex here";
in {
  theme = {
    enable = true;
    name = "dark";
  };

  coding = {
    cpp.enable = true;
    go.enable = true;
    node.enable = true;
    java.enable = true;
    sql.enable = true;
  };

  program.app = {
    waydroid.enable = true;
    ani-cli.enable = true;
    codium.enable = true;
    docker.enable = true;
    firefox = {
      enable = true;
      username = username;
    };
    opencode.enable = true;
    kilo.enable = true;
    free-models.enable = true;
    lutris.enable = true;
    minecraft.enable = true;
    notes.enable = true;
    obs.enable = true;
    office.enable = true;
    ollama = {
      enable = true;
      username = username;
    };
    quickshell.enable = true;
    rustdesk.enable = true;
    sunshine.enable = true;
    spotify.enable = true;
    virtual-machine.enable = true;
    networking-tools.enable = true;
    media.enable = true;
    drawing.enable = true;
    kubernetes.enable = true;
    adb.enable = true;
  };

  users.users.${username} = {
    inherit description;
    isNormalUser = true;
    extraGroups = [
      "docker"
      "networkmanager"
      "wheel"
      "libvirtd"
      "i2c"
      "video"
      "plugdev"
    ];
    packages = with pkgs; [
      btop
      git
      ripgrep
      firefox
      vesktop
      equibop
      alacritty
      openssh
    ];
  };

  hjem.users.${username} = {
    enable = true;
    user = username;
    directory = config.users.users.${username}.home;
    clobberFiles = lib.mkForce true;
    files = let
      config_path = "../.config";
      hypr_user_conf = ./${username}/config/hyprland/hyprland.conf;
      hypr_system_path = ../device/${settings.hostName}/.config/hypr/hyprland.conf;
      hypr_system_conf =
        if builtins.pathExists hypr_system_path
        then builtins.readFile hypr_system_path
        else "";
      hypr_global_conf = ./${config_path}/hypr/hyprland.conf;
      hypr_user_conf_replaced = let
        from = ["{{cursor_theme_name}}"];
        to = ["Bibata-Modern-Classic"];
      in
        lib.mkForce (builtins.replaceStrings from to (builtins.readFile hypr_user_conf));
    in {
      ".config/hypr/hyprland.conf".text =
        builtins.readFile hypr_global_conf + hypr_system_conf + hypr_user_conf_replaced.content;
      ".bashrc".text = builtins.readFile ./${config_path}/bashrc;
    };
  };
}
