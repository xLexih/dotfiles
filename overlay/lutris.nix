final: prev: {
  lutris-custom = prev.lutris.override {
    extraPkgs = p: with p; [
      wineWow64Packages.stagingFull
      wineWow64Packages.waylandFull
      winetricks
      mono
      samba
      krb5
      cabextract
      unzip
      p7zip
      vkd3d-proton
      dxvk
      vulkan-loader
      vulkan-tools
    ];
  };
}
