{pkgs, ...}: {
  nix.settings.use-xdg-base-directories = true;

  environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";

    # Shell
    HISTFILE = "$HOME/.local/state/bash/history";
    NODE_REPL_HISTORY = "$HOME/.local/state/node_repl_history";

    # Docker
    DOCKER_CONFIG = "$HOME/.config/docker";

    # Gradle
    GRADLE_USER_HOME = "$HOME/.local/share/gradle";

    # npm
    NPM_CONFIG_CACHE = "$HOME/.cache/npm";
    NPM_CONFIG_INIT_MODULE = "$HOME/.config/npm/config/npm-init.js";
    NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";

    # CUDA
    CUDA_CACHE_PATH = "$HOME/.cache/nv";

    # Wakatime
    WAKATIME_HOME = "$HOME/.config/wakatime";

    # Java / OpenJFX
    _JAVA_OPTIONS =
      "-Djava.util.prefs.userRoot=$HOME/.config/java "
      + "-Djavafx.cachedir=$HOME/.cache/openjfx";

    # NuGet / .NET
    NUGET_PACKAGES = "$HOME/.cache/nuget";
    DOTNET_CLI_HOME = "$HOME/.local/share/dotnet";
  };

  environment.systemPackages = with pkgs; [
    xdg-ninja
  ];
}
