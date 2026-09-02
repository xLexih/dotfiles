{...}: {
  security.rtkit.enable = true; # realtime scheduling for audio

  services.pulseaudio.enable = false; # replaced by pipewire

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # for 32-bit games
    pulse.enable = true; # pulseaudio compatibility
    jack.enable = true; # pro audio compatibility
    wireplumber = {
      enable = true;
      extraConfig."10-momentum-4-bluetooth" = {
        "wireplumber.settings" = {
          "bluetooth.profile-preference" = "quality";
          "bluetooth.autoswitch-to-headset-profile" = true;
        };
        "monitor.alsa.rules" = [
          {
            matches = [{"node.name" = "alsa_input.pci-0000_00_1f.3.analog-stereo";}];
            actions = {"update-props" = {"priority.session" = 2020;};};
          }
        ];
        "monitor.bluez.rules" = [
          {
            matches = [{"api.bluez5.address" = "80:C3:BA:2A:7F:F4";}];
            actions = {
              update-props = {
                "device.profile" = "a2dp-sink";
                "bluez5.auto-connect" = ["a2dp_sink"];
              };
            };
          }
        ];
      };
    };
  };
}
