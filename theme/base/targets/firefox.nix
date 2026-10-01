# Firefox through its theme API, using Pywalfox: the extension reads a
# pywal-style palette (~/.cache/wal/colors.json) from its native host and
# applies it with browser.theme, so toolbars, tabs, menus, the sidebar
# (Sidebery's "Firefox" color scheme) and the new tab page follow it without a
# restart. about: pages and websites follow the dark/light preference from GTK.
{
  lib,
  pkgs,
  ...
}: let
  pywalfox = lib.getExe pkgs.pywalfox-native;

  nativeHost = pkgs.writeTextDir "lib/mozilla/native-messaging-hosts/pywalfox.json" (builtins.toJSON {
    name = "pywalfox";
    description = "Pywalfox native messaging host";
    path = pywalfox;
    type = "stdio";
    allowed_extensions = ["pywalfox@frewacom.org"];
  });

  # Pywalfox's templates pick fixed indices: dark mode uses 0 (background),
  # 10/13 (accents) and 15 (text); light mode uses 7 (background), 3/5
  # (accents) and 0 (text). The rest only fill the list.
  walColors = theme: let
    p = theme.palette;
    t = theme.terminal.normal;
    dark = theme.variant == "dark";
    colors =
      if dark
      then [p.bg t.red t.green t.yellow t.blue t.magenta t.cyan p.fg p.overlay t.red p.accent t.yellow t.blue p.accentAlt t.cyan p.fg]
      else [p.fg t.red t.green p.accent t.blue p.accentAlt t.cyan p.bg p.fgMuted t.red t.green t.yellow t.blue t.magenta t.cyan p.bg];
  in
    # Pywalfox reads the colors in file order, so the JSON is written by hand.
    ''
      {
        "wallpaper": "",
        "colors": {
      ${lib.concatStringsSep ",\n" (lib.imap0 (i: color: ''"color${toString i}": "${color}"'') colors)}
        }
      }
    '';
in {
  programs.firefox = {
    nativeMessagingHosts.packages = [nativeHost];
    policies.ExtensionSettings."pywalfox@frewacom.org" = {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/pywalfox/latest.xpi";
    };
  };

  modules.theme = {
    render.firefox = theme: {".cache/wal/colors.json" = walColors theme;};
    reload.firefox = ''
      ${pywalfox} "$(theme_get .variant)" >/dev/null
      ${pywalfox} update
    '';
  };
}
