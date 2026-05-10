{ config, pkgs, ... }:

{

  systemd.services.systemd-modules-load = {
    enable = true; # This is potentially a breaking change, disable at your own risk. (saves 3-5s tho...)
    # I suspect it double loads the kernel modules making it slooooooooooooooooooow
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Don't block other services
      Before = [ "sysinit.target" ];
      DefaultDependencies = false;
    };
  };
  
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "rd.systemd.show_status=auto"
    "acpi_enforce_resources=lax" 
    "hpet=disable" 
    "i8042.nopnp"
    "libahci.ignore_sss=1"
  ];
  services.syslogd.enable = false; # Disable syslog-ng
  boot.initrd.compressor = "zstd";
  boot.blacklistedKernelModules = [ "intel-hid" ];
}