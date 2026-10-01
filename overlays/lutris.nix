# Lutris with Wine (staging and wayland builds), DXVK/VKD3D and installer tools
# in its FHS environment.
final: prev: {
  lutris-custom = prev.lutris.override {
    extraPkgs = p:
      with p; [
        cabextract
        dxvk
        krb5
        mono
        p7zip
        samba
        unzip
        vkd3d-proton
        vulkan-loader
        vulkan-tools
        wineWow64Packages.stagingFull
        wineWow64Packages.waylandFull
        winetricks
      ];
  };
}
