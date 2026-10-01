# obs-move-transition 3.2.1 still calls `obs_properties_add_button`, which OBS
# 32 marks deprecated; with -Werror that fails the build. Keep it a warning.
final: prev: {
  obs-studio-plugins =
    prev.obs-studio-plugins
    // {
      obs-move-transition = prev.obs-studio-plugins.obs-move-transition.overrideAttrs (old: {
        NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -Wno-error=deprecated-declarations";
      });
    };
}
