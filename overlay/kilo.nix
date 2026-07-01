final: prev: let
  nodejs = prev.nodejs_24;
  kiloVersion = "latest";
in {
  kilo = prev.buildFHSEnv {
    name = "kilo";
    targetPkgs = p: [
      nodejs
      p.coreutils
      p.bash
      p.stdenv.cc.cc.lib
      p.glibc
      p.zlib
      p.openssl
      p.icu
      p.libgcc
    ];
    runScript = prev.writeShellScript "kilo-inner" ''
      export PATH="${nodejs}/bin:$PATH"

      KILO_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/kilocode-cli"

      if [ ! -d "$KILO_DIR/node_modules" ]; then
        echo "First run: installing @kilocode/cli@${kiloVersion}..."
        mkdir -p "$KILO_DIR"
        cd "$KILO_DIR"
        npm init -y > /dev/null 2>&1
        npm install @kilocode/cli@${kiloVersion}
      fi

      exec "$KILO_DIR/node_modules/.bin/kilo" "$@"
    '';
  };
}
