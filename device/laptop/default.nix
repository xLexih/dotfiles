# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  settings,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./boot.nix
    ./battery.nix
  ];

  batteryOptimize = {
    enable = true;
    aggressivePowerSave.enable = true;
    undervolt.enable = false; # Disabled - may need BIOS unlock or different approach
    gpuPowerStates.enable = true; # Enable Intel GPU deep power states
    teoIdleGovernor.enable = true; # Use TEO idle governor for more aggressive power saving
    coreParking.enable = false; # Disabled by default - enable to park E-cores on battery
  };
  program.app.hyprland = {
    enable = true;
  };
  boot.initrd.availableKernelModules = [
    "nvme" # SSD controller
    # "xhci_pci"       # USB controller
    # "usbhid"         # Input devices
    "ext4"
    # "fat"
  ];
  boot.kernelModules = [
    "kvm_intel" # Intel virtualization
    "yt6801" # Motorcomm Ethernet
    "asus_wmi" # For power managment
    "asus_nb_wmi" # For power managment
    "tuxedo-keyboard"
  ];
  boot.blacklistedKernelModules = ["ite_8291"];
  boot.kernelParams = [
    "i8042.nopnp"
    # "usbhid.s=0x048d:0x600b:0x0004,0x048d:0x7001:0x0004"
  ];
  # no longer want to block them, they give me access to controllers
  # boot.blacklistedKernelModules = [ "asus_wmi" "asus_nb_wmi" "spi_nor" "proc_thermal_pci"];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    acpi_call
    tuxedo-drivers
    yt6801
  ];
  #services.udev.extraRules = ''
  #  SUBSYSTEM=="leds", KERNEL=="rgb:kbd_backlight_*", ACTION=="add", ATTR{brightness}="0", OPTIONS+="link_priority=100"
  #'';
  systemd.services."systemd-backlight@leds:rgb:kbd_backlight".enable = false;

  hardware.acpilight.enable = true;
  services.system76-scheduler.settings.cfsProfiles.enable = true;
  services.upower.enable = true;
  environment.systemPackages = with pkgs; [
    brightnessctl
    hid-send
    gnupg
    pinentry-curses
  ];
  # Override the package to BETA for newer drivers. (TESTING)
  hardware.nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.beta;

  graphicsModule = {
    intel.enable = true;
    dgpu = "pci-0000:01:00.0-card";
    igpu = "pci-0000:00:02.0-card";
    nvidia = {
      enable = true; # temporary disabled.
      hybrid = {
        enable = true;
        igpu = {
          vendor = "intel";
          # lspci | grep -E "VGA|3D"
          # lshw -c display
          port = "PCI:0:2:0"; # 00:02.0: Raptor Lake-S UHD | pci@0000:00:02.0
        };
        dgpu.port = "PCI:1:0:0"; # 01:00.0: GeForce RTX 4060 Max-Q | pci@0000:01:00.0
      };
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 0;

  networking.hostName = settings.hostName;
  networking.networkmanager.enable = true;
  environment.variables = {
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    MOZ_ENABLE_WAYLAND = "1";
  };

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true; # optional
  };
}
