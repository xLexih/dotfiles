# Firefox: theme.css styles the browser window, menus, about: pages and
# Sidebery. Firefox only reads userChrome.css at startup, so a small AutoConfig
# script registers ~/.config/theme/firefox.css as a user style sheet instead
# and swaps it whenever `theme` replaces the file: switches apply live in the
# window, menus, about: pages, web pages and Sidebery, with the theme's exact
# colors and no extension.
{
  lib,
  pkgs,
  ...
}: let
  inherit (import ../../lib.nix {inherit lib;}) cssVariables;

  loader = ''
    // Loads ~/.config/theme/firefox.css as a user style sheet and reloads it
    // when the file changes (checked every second).
    (() => {
      const { classes: Cc, interfaces: Ci, utils: Cu } = Components;
      const sheets = Cc["@mozilla.org/content/style-sheet-service;1"].getService(Ci.nsIStyleSheetService);
      const io = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService);
      const file = Cc["@mozilla.org/file/directory_service;1"].getService(Ci.nsIProperties).get("Home", Ci.nsIFile);
      for (const part of [".config", "theme", "firefox.css"]) file.append(part);

      let sheet = null;
      let stamp = 0;
      const load = () => {
        try {
          if (!file.exists() || file.lastModifiedTime === stamp) return;
          stamp = file.lastModifiedTime;
          const input = Cc["@mozilla.org/network/file-input-stream;1"].createInstance(Ci.nsIFileInputStream);
          input.init(file, -1, 0, 0);
          const reader = Cc["@mozilla.org/intl/converter-input-stream;1"].createInstance(Ci.nsIConverterInputStream);
          reader.init(input, "UTF-8", 0, 0);
          let css = "";
          const chunk = {};
          while (reader.readString(65536, chunk)) css += chunk.value;
          reader.close();
          // A data: URI, so sandboxed content processes (web pages, extensions)
          // don't need to read files in $HOME.
          const next = io.newURI("data:text/css;charset=utf-8," + encodeURIComponent(css));
          sheets.loadAndRegisterSheet(next, sheets.USER_SHEET);
          if (sheet) sheets.unregisterSheet(sheet, sheets.USER_SHEET);
          sheet = next;
        } catch (error) {
          Cu.reportError(error);
        }
      };

      load();
      const timer = Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer);
      timer.initWithCallback({ notify: load }, 1000, Ci.nsITimer.TYPE_REPEATING_SLACK);
      // Keeps the timer referenced for the lifetime of the browser.
      Cc["@mozilla.org/observer-service;1"].getService(Ci.nsIObserverService)
        .addObserver({ observe() {}, timer }, "theme-style-sheet-loader");
    })();
  '';
in {
  programs.firefox = {
    # AutoConfig runs with full privileges only outside its sandbox.
    package = pkgs.firefox.override {
      extraAutoConfig = ''pref("general.config.sandbox_enabled", false);'';
    };
    autoConfig = loader;
    policies.Preferences = {
      "svg.context-properties.content.enabled" = true;
      "widget.gtk.native-context-menus" = false;
    };
  };

  modules.theme.render.firefox = theme: {
    ".config/theme/firefox.css" = cssVariables "theme" theme.colors + "\n" + builtins.readFile ./theme.css;
  };
}
