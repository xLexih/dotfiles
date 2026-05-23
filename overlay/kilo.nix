final: prev: let
  nodejs = prev.nodejs_24;
  pnpm = prev.pnpm;
  kiloVersion = "latest";
in {
  kilo = prev.buildFHSEnv {
    name = "kilo";
    targetPkgs = p: [
      nodejs
      pnpm
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
      export PATH="${nodejs}/bin:${pnpm}/bin:$PATH"
      export PNPM_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
      export PATH="$PNPM_HOME:$PATH"

      KILO_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/kilocode-cli"

      if [ ! -d "$KILO_DIR/node_modules" ]; then
        echo "First run: installing @kilocode/cli@${kiloVersion}..."
        mkdir -p "$KILO_DIR"
        cd "$KILO_DIR"
        pnpm init > /dev/null 2>&1
        pnpm add @kilocode/cli@${kiloVersion}
      fi

      exec "$KILO_DIR/node_modules/.bin/kilo" "$@"
    '';
  };
}
