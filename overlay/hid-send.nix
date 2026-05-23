final: prev: {
  hid-send = prev.stdenv.mkDerivation {
    pname = "hid-send";
    version = "0.0.1";
    src = ../overlay/hid-send-src;
    nativeBuildInputs = [prev.gcc];

    buildPhase = ''
      runHook preBuild
      g++ hid_send.cpp -o hid-send
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp hid-send $out/bin/
      runHook postInstall
    '';
  };
}
