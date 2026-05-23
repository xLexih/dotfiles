{
  modulesPath,
  config,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10; # don't keep too many generations
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.timeout = 0; # skip menu, hold space to show
  boot.supportedFilesystems = ["ntfs"];
  boot.kernelModules = [
    "kvm_intel" # Intel virtualization
    "yt6801" # Motorcomm Ethernet
    "asus_wmi" # For power managment
    "asus_nb_wmi" # For power managment
    "tuxedo-keyboard"
  ];
  boot.blacklistedKernelModules = ["ite_8291"];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    acpi_call
    tuxedo-drivers
    yt6801
  ];
}
