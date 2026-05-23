{...}: {
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/a63fe885-b94e-42a2-8330-9ba4f5df57df";
    fsType = "ext4";
    options = ["noatime" "nodiratime" "discard"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/CD0B-0C93";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077" "noatime" "nodiratime"];
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/e7f8b63d-b2b2-4cbe-a825-6fde9c6d7afb";
    fsType = "btrfs";
    options = ["noauto" "comment=systemd.automount" "x-systemd.automount"];
  };

  zramSwap.enable = true;
  zramSwap.algorithm = "lz4";
}
