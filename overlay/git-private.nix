final: prev: let
  template = ../template/git-private;
in {
  git-private = prev.writeShellApplication {
    name = "git-private";
    runtimeInputs = with prev; [coreutils git gnused just];
    text = ''
      set -Eeuo pipefail

      template=${prev.lib.escapeShellArg template}

      usage() {
        cat >&2 <<USAGE
      usage:
        git private init [PATH] [--force]
        git private <check|encrypt|decrypt|...>

      init creates a Git repository from the git-private flake template.
      Other commands dispatch to the current repository's scripts/private.
      USAGE
      }

      die() {
        printf 'git-private: %s\n' "$*" >&2
        exit 1
      }

      copy_template() {
        local target="$1"
        local force="$2"
        local path
        local collisions=0

        for path in .gitignore flake.nix flake.lock justfile scripts/private scripts/pre-commit; do
          if [ -e "$target/$path" ] && [ "$force" != 1 ]; then
            printf 'git-private: refusing to overwrite %s\n' "$target/$path" >&2
            collisions=1
          fi
        done

        [ "$collisions" = 0 ] || die "rerun with --force to overwrite template files."
        cp -R -- "$template/." "$target/"
        chmod +x "$target/scripts/private" "$target/scripts/pre-commit"
        git -C "$target" add -N -- .gitignore flake.nix flake.lock justfile scripts/private scripts/pre-commit
      }

      init_repo() {
        local target="."
        local force=0

        while [ "$#" -gt 0 ]; do
          case "$1" in
            --force) force=1; shift ;;
            --help | -h) usage; exit 0 ;;
            *)
              [ "$target" = "." ] || die "init accepts at most one path."
              target="$1"
              shift
              ;;
          esac
        done

        mkdir -p -- "$target"
        target="$(cd "$target" && pwd -P)"

        if [ ! -d "$target/.git" ]; then
          git init "$target"
        fi

        copy_template "$target" "$force"
        (cd "$target" && just setup)

        printf 'git-private: initialized %s\n' "$target"
      }

      dispatch_repo_command() {
        local root
        root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a Git repository. Use: git private init [PATH]"
        [ -x "$root/scripts/private" ] || die "missing executable scripts/private in $root"
        exec "$root/scripts/private" "$@"
      }

      command="''${1:-}"
      case "$command" in
        init) shift; init_repo "$@" ;;
        help | --help | -h | "") usage ;;
        *) dispatch_repo_command "$@" ;;
      esac
    '';
  };
}
