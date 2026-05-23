{...}: {
  security.rtkit.enable = true; # realtime scheduling for audio

  services.pulseaudio.enable = false; # replaced by pipewire

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # for 32-bit games
    pulse.enable = true; # pulseaudio compatibility
    jack.enable = true; # pro audio compatibility
    wireplumber.enable = true;
  };
}
