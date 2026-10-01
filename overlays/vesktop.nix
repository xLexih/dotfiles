# Wayland screen sharing: enable Chromium's PipeWire capturer, without it the
# portal picker closes and the stream ends right away (Hyprland + NVIDIA).
final: prev: {
  vesktop = prev.vesktop.overrideAttrs (old: {
    postFixup =
      (old.postFixup or "")
      + ''
        substituteInPlace $out/bin/vesktop \
          --replace-fail "WaylandWindowDecorations" "WaylandWindowDecorations,WebRTCPipeWireCapturer"
      '';
  });
}
