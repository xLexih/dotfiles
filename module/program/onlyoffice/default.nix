{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    onlyoffice-bin
  ];
  fonts.packages = with pkgs; [
    corefonts
  ];
}
