{...}: {
  fileSystems."/" = {
    device = "/dev/disk/by-label/ROOT";
    fsType = "ext4";
    options = ["noatime" "nodiratime" "discard"];
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-label/DATA";
    fsType = "ext4";
    options = ["noauto" "comment=systemd.automount" "x-systemd.automount"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6B36-A50E";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077" "noatime" "nodiratime"];
  };
}
