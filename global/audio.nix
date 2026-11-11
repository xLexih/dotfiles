{
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # The X11 bell module connects to Xwayland and segfaults PipeWire when
    # Xwayland goes away (every logout and shutdown).
    extraConfig.pipewire."10-no-x11-bell"."context.properties"."module.x11.bell" = false;

    wireplumber.extraConfig."10-momentum-4-bluetooth" = {
      "wireplumber.settings" = {
        "bluetooth.profile-preference" = "quality";
        # Classic Bluetooth can't carry A2DP music and a microphone at once:
        # with this on, any app recording from the headset mic (Discord,
        # Minecraft voice chat) flips the headphones to HFP/mSBC (16 kHz mono).
        # Off, they stay on A2DP (aptX HD) and apps record from the laptop
        # mic. To use the headset mic anyway, pick the "Headset Head Unit"
        # profile in pwvucontrol.
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
      "monitor.alsa.rules" = [
        {
          matches = [{"node.name" = "alsa_input.pci-0000_00_1f.3.analog-stereo";}];
          actions.update-props."priority.session" = 2020;
        }
      ];
      "monitor.bluez.rules" = [
        {
          matches = [{"api.bluez5.address" = "80:C3:BA:2A:7F:F4";}];
          actions.update-props = {
            "device.profile" = "a2dp-sink";
            "bluez5.auto-connect" = ["a2dp_sink"];
          };
        }
      ];
    };
  };
}
