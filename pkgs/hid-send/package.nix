{stdenv}:
stdenv.mkDerivation {
  pname = "hid-send";
  version = "0.0.1";
  src = ./.;

  buildPhase = ''
    runHook preBuild
    $CXX -Wall -Wextra -O2 hid_send.cpp -o hid-send
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 hid-send $out/bin/hid-send
    runHook postInstall
  '';

  meta.mainProgram = "hid-send";
}
