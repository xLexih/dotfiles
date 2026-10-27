# Keeps tools out of $HOME. These are session variables (PAM) rather than
# .bashrc exports so Hyprland, everything launched from it and systemd user
# services see them too, not only interactive shells. Values spell out $HOME
# because pam_env can't reference variables defined later in the file.
{
  environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    XDG_CACHE_HOME = "$HOME/.cache";

    CARGO_HOME = "$HOME/.local/share/cargo";
    CLAUDE_CONFIG_DIR = "$HOME/.config/claude";
    CODEX_HOME = "$HOME/.config/codex";
    CUDA_CACHE_PATH = "$HOME/.cache/nv";
    DOCKER_CONFIG = "$HOME/.config/docker";
    DOTNET_CLI_HOME = "$HOME/.local/share/dotnet";
    GNUPGHOME = "$HOME/.local/share/gnupg";
    GOPATH = "$HOME/.local/share/go";
    GRADLE_USER_HOME = "$HOME/.local/share/gradle";
    KUBECACHEDIR = "$HOME/.cache/kube";
    KUBECONFIG = "$HOME/.config/kube/config";
    LESSHISTFILE = "$HOME/.local/state/less/history";
    MAVEN_OPTS = "-Dmaven.repo.local=$HOME/.cache/maven/repository";
    NODE_REPL_HISTORY = "$HOME/.local/state/node/repl_history";
    NPM_CONFIG_CACHE = "$HOME/.cache/npm";
    NPM_CONFIG_INIT_MODULE = "$HOME/.config/npm/config/npm-init.js";
    NPM_CONFIG_USERCONFIG = "$HOME/.config/npm/npmrc";
    NUGET_PACKAGES = "$HOME/.cache/nuget";
    PERF_BUILDID_DIR = "$HOME/.cache/perf";
    PI_CODING_AGENT_DIR = "$HOME/.config/pi/agent";
    PULSE_COOKIE = "$HOME/.config/pulse/cookie";
    PYTHON_HISTORY = "$HOME/.local/state/python_history";
    RUSTUP_HOME = "$HOME/.local/share/rustup";
    WAKATIME_HOME = "$HOME/.config/wakatime";
    WGETRC = "$HOME/.config/wget/wgetrc";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=$HOME/.config/java -Djavafx.cachedir=$HOME/.cache/openjfx";
  };
}
