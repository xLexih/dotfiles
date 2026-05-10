{
  lib,
  config,
  pkgs,
  settings,
  ...
}: let
  cfg = config.program.app.firefox;
in {
  options.program.app.firefox = {
    enable = lib.mkEnableOption "Firefox with custom config and extensions";
    username = lib.mkOption {
      type = lib.types.str;
      default = "lex";
    };
  };

  config = lib.mkIf cfg.enable {
    hjem.users = lib.attrsets.genAttrs settings.users (username: {
      files = {
        ".mozilla/firefox/default/user.js".text = ''
          user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
          user_pref("svg.context-properties.content.enabled", true);
        '';

        ".mozilla/firefox/default/chrome/userContent.css".text = ''
          #root.root {
            --color-accent-primary: #dbb0ffee !important;
            --frame-bg: rgb(42, 17, 68) !important;
            --frame-fg: var(--color-accent-primary) !important;
            --toolbar-fg: var(--frame-fg) !important;
            --border: rgb(42, 17, 68) !important;
            --notification-bg: rgb(42, 17, 68) !important;
            --ctx-menu-bg: rgb(42, 17, 68) !important;
            --ctx-menu-fg: var(--color-accent-primary);
            --ctx-menu-separator: rgb(42, 17, 68) !important;
            --popup-bg: rgb(42, 17, 68) !important;;
            --tabs-normal-fg: color-mix(in oklab, #dbb0ffee, transparent 35%) !important;
            --tabs-activated-fg: var(--color-accent-primary) !important;
            --tabs-activated-bg: color-mix(in oklab, #dbb0ffee, transparent 75%) !important;

            --toolbar-bg: rgb(42, 17, 68) !important;
          }
          body {
            --newtab-background-color: rgb(42, 17, 68) !important;
            --newtab-background-color-secondary: color-mix(in oklab, var(--newtab-background-color), black 20%) !important;
            --newtab-background-card: var(--newtab-background-color-secondary) !important;
          }
        '';

        ".mozilla/firefox/default/chrome/userChrome.css".text = ''
          :root{
            --toolbar-bgcolor:rgb(42, 17, 68) !important;
            --urlbar-box-bgcolor: color-mix(in oklab, var(--toolbar-bgcolor), black 20%) !important;
            --color-accent-primary: #dbb0ffee !important;
            --toolbarbutton-icon-fill: var(--color-accent-primary) !important;
            --toolbar-field-background-color: color-mix(in oklab, var(--toolbar-bgcolor), black 20%) !important;
            --toolbar-field-focus-background-color: color-mix(in oklab, var(--toolbar-bgcolor), black 20%) !important;
            --toolbarbutton-special-border-radius: 0px 0px 15px 15px / 15px !important;
            --urlbarView-highlight-background: color-mix(in oklab, var(--color-accent-primary), transparent 50%) !important;
            --toolbarbutton-icon-fill-attention: color-mix(in oklab, var(--color-accent-primary), transparent 20%) !important;
            --urlbarView-action-color: color-mix(in oklab, var(--color-accent-primary), transparent 20%) !important;

            --s-frame-bg: var(--toolbar-bgcolor) !important;
            --s-border: var(--s-frame-bg) !important;
            --s-notification-bg: var(--s-frame-bg) !important;
            --s-ctx-menu-bg: var(--s-frame-bg) !important;
            --s-ctx-menu-separator: var(--s-frame-bg) !important;
            --s-popup-bg: var(--s-frame-bg) !important;
            --s-tabs-activated-bg: color-mix(in oklab, var(--color-accent-primary), transparent 75%) !important;
            --s-toolbar-bg: var(--s-frame-bg) !important;
            --chrome-content-separator-color: var(--color-accent-primary) !important;
            --arrowpanel-border-color: var(--chrome-content-separator-color) !important;
            --toolbar-color: var(--color-accent-primary) !important;
          }

          #urlbar:is([focused], [open])[breakout-extend] > #urlbar-background {
            border-radius: var(--toolbarbutton-special-border-radius) !important;
          }
          #statuspanel-label {
            background-color: var(--color-accent-primary) !important;
            color: var(--toolbar-bgcolor) !important
          }
          toolbarbutton,
          .urlbar-input {
            color: var(--color-accent-primary) !important;
          }
          #identity-box,
          #tracking-protection-icon-container,
          .urlbar-icon {
            fill: var(--color-accent-primary) !important;
          }
          .translations-button {
            display: inherit;
          }
          #TabsToolbar,
          #sidebar-header,
          #sidebar-splitter-disabled {
            display: none !important;
          }
        '';
      };
    });

    programs.firefox = {
      enable = true;
      package = pkgs.firefox;

      policies = {
        DisableTelemetry = true;
        Preferences = {
          "svg.context-properties.content.enabled" = true;
          "layout.css.color-mix-multi-color.enabled" = true;
          "dom.ipc.processCount" = 4; # 8 is default, trying to save battery!
          "ui.systemUsesDarkTheme" = true;
          "browser.aboutConfig.showWarning" = false;
          "widget.gtk.hide-pointer-while-typing.enabled" = false;
          "findbar.highlightAll" = true;
          "accessibility.force_disabled" = 1;
          "extensions.pocket.enabled" = false;
          "browser.vpn_promo.enabled" = false;
          "browser.newtabpage.activity-stream.feeds.recommendationprovider" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "browser.tabs.closeWindowWithLastTab" = false;
          "browser.shell.checkDefaultBrowser" = false;

          "signon.rememberSignons" = false;
          "signon.autofillForms" = false;
          "browser.formfill.enable" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "browser.tabs.min_inactive_duration_before_unload" = 150000;
          "browser.cache.memory.enable" = true;
          "browser.cache.memory.capacity" = 1048576;
          "browser.cache.memory.max_entry_size" = -1;
          "browser.cache.disk.enable" = false;
          "browser.cache.disk.smart_size.enabled" = false;

          "browser.urlbar.placeholderName" = "me";

          "keyword.enabled" = true;
          "browser.urlbar.suggest.history" = false;
          "browser.urlbar.suggest.bookmark" = false;
          "browser.urlbar.suggest.recentsearches" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.trending" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.yelp" = false;
          "browser.urlbar.suggest.addons" = false;

          "browser.urlbar.trimURLs" = false;
        };
        ExtensionSettings = {
          "firefox@tampermonkey.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpi";
          };
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
          "{ddc62400-f22d-4dd3-8b4a-05837de53c2e}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/read-aloud/latest.xpi";
          };
          "{3c078156-979c-498b-8990-85f7987dd929}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
          };
          "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
          };
          "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi";
          };
          "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/auto-tab-discard/latest.xpi";
          };
        };
      };
    };
  };
}
