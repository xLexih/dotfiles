final: prev: {
  vesktop = prev.vesktop.overrideAttrs (old: {
    # Fix Wayland screenshare: ensure Chromium's PipeWire capturer is enabled.
    # The upstream wrapper only enables WaylandWindowDecorations; on Hyprland+NVIDIA
    # the WebRTC PipeWire path is otherwise not reliably enabled and the portal
    # picker returns then the stream is immediately torn down ("selector then nothing").
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [prev.makeWrapper];
    postFixup =
      (old.postFixup or "")
      + ''
        # Inject WebRTCPipeWireCapturer into the existing --enable-features flag.
        # Wrapper line: --enable-features=WaylandWindowDecorations --enable-wayland-ime=true
        # -> --enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer --enable-wayland-ime=true
        if grep -q "WaylandWindowDecorations" "$out/bin/vesktop"; then
          substituteInPlace "$out/bin/vesktop" \
            --replace "WaylandWindowDecorations" "WaylandWindowDecorations,WebRTCPipeWireCapturer"
        fi
      '';
  });
}
