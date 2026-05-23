final: prev: let
  pkgsLutris = prev.extend (lfinal: lprev: {
    openldap = lprev.openldap.overrideAttrs (_: {
      doCheck = false;
    });
  });
in {
  lutris-custom = pkgsLutris.buildEnv {
    name = "lutris-custom";
    paths = with pkgsLutris; [
      lutris # game manager
      wineWow64Packages.stable # Wine stable
      wineWow64Packages.staging # Wine staging
      wineWow64Packages.waylandFull # wayland Wine runtime
      winetricks # Wine helper scripts
      mono # .NET runtime for Wine
      samba # Windows network helpers
      krb5 # kerberos runtime used by some Wine setups
      cabextract # cabinet extraction
      unzip # zip extraction
      p7zip # 7z archive support
      vkd3d-proton # DirectX 12 translation
      dxvk # DirectX 9/10/11 translation
      vulkan-loader # Vulkan ICD loader
      vulkan-tools # vulkaninfo
    ];
    ignoreCollisions = true;
  };
}
