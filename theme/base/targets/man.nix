# Themed man colors. less renders bold/underline/standout via TERMCAP,
# so man follows `theme set` in new shells without a rebuild.
{lib, ...}: let
  inherit (import ../lib.nix {inherit lib;}) rgb;
  sgr = color: let c = rgb color; in "${toString c.r};${toString c.g};${toString c.b}";
in {
  modules.theme.render.man = theme: let
    dark = theme.variant == "dark";
    header =
      if dark
      then theme.colors.focus
      else theme.colors.accentBright;
    under =
      if dark
      then theme.colors.link
      else theme.colors.green;
  in {
    ".config/theme/man.sh" = ''
      export MANROFFOPT='-c'
      export MANPAGER='less -R'
      export LESS_TERMCAP_mb=$'\e[1;38;2;${sgr theme.colors.red}m'
      export LESS_TERMCAP_md=$'\e[1;38;2;${sgr header}m'
      export LESS_TERMCAP_me=$'\e[0m'
      export LESS_TERMCAP_so=$'\e[48;2;${sgr theme.colors.selectionBg};38;2;${sgr theme.colors.selectionFg}m'
      export LESS_TERMCAP_se=$'\e[0m'
      export LESS_TERMCAP_us=$'\e[4;38;2;${sgr under}m'
      export LESS_TERMCAP_ue=$'\e[0m'
    '';
  };
}
