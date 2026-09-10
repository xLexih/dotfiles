# obs-move-transition 3.2.1 (latest release) still calls the deprecated
# `obs_properties_add_button`, which OBS 32+ headers mark `OBS_DEPRECATED`.
# Nixpkgs' stdenv enables `-Werror`, so the deprecation is promoted to a hard
# build error (`cc1: all warnings being treated as errors`). The plugin build
# is otherwise fine — this demotes exactly that diagnostic back to a warning
# without touching source or downgrading OBS.
final: prev: {
  obs-studio-plugins = prev.obs-studio-plugins // {
    obs-move-transition = prev.obs-studio-plugins.obs-move-transition.overrideAttrs (attrs: {
      NIX_CFLAGS_COMPILE = (attrs.NIX_CFLAGS_COMPILE or "") + " -Wno-error=deprecated-declarations";
    });
  };
}
