# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/firefox.nix
# https://gitlab.com/scientiac/tesseract.home.manager/-/blob/main/apps/graphical/firefox/default.nix#L9
{
  pkgs,
  settings,
  inputs,
  lib,
  ...
}: {
  options.firefox.username = lib.mkOption {
    type = lib.types.string;
    default = "lex";
  };
  # ~/.mozilla/firefox/<profile-folder>/chrome/userChrome.css
  /*
  Once you've set up the Browser Toolbox, you can use its Inspector tool to examine an UI element.
  After doing so, in the source code pane of the Inspector tab, right-click that element and choose Show DOM Properties.
  Then in the bottom right corner, look for the namespaceURI property.
  If it says http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul
  it's usually a good bet code for that element belongs in userChrome.css,
  while http://www.w3.org/1999/xhtml suggests userContent.css is where it should go.
  https://www.reddit.com/r/FirefoxCSS/comments/7dtd91/comment/dqalebo/
  */
  config.hjem.users = lib.attrsets.genAttrs settings.users (username: {
    files = {
      ".mozilla/firefox/default/chrome/userContent.css".text = ''
        #root.root {
          --frame-bg: rgb(42, 17, 68) !important;
          --border: rgb(42, 17, 68) !important;
          --notification-bg: rgb(42, 17, 68) !important;
          --ctx-menu-bg: rgb(42, 17, 68) !important;
          --ctx-menu-separator: rgb(42, 17, 68) !important;
          --popup-bg: rgb(42, 17, 68) !important;
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
          --color-accent-primary: #dbb0ffee !important;
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
          --chrome-content-separator-color: color-mix(in oklab, var(--color-accent-primary), transparent 75%) !important;
        }

        /* Does the special rounding once the URL bar is opened. */
        #urlbar:is([focused], [open])[breakout-extend] > #urlbar-background {
          border-radius: var(--toolbarbutton-special-border-radius) !important;
        }
        /* Fixes the URL shown in the bottom left corner. */

        #statuspanel-label {
          background-color: var(--s-tabs-activated-bg) !important;
        }

        /* hides the tabs and the left useless part. */
        #TabsToolbar,
        #sidebar-header,
        #sidebar-splitter {
          display: none !important;
        }
      '';
    };
  });

  config.programs.firefox = {
    enable = true;
    package = inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin;
    policies = {
      DisableTelemetry = true;
      Preferences = {
        "browser.aboutConfig.showWarning" = false;
        "widget.gtk.hide-pointer-while-typing.enabled" = false;
        "findbar.highlightAll" = true;
        "accessibility.force_disabled" = 1; # saves ram
        "extensions.pocket.enabled" = false;
        "browser.vpn_promo.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.recommendationprovider" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "browser.tabs.closeWindowWithLastTab" = false;
        "browser.shell.checkDefaultBrowser" = false;

        "signon.rememberSignons" = false; # Disable Ask to save logins and passwords for websites"
        "signon.autofillForms" = false; # Disable "Autofill logins and passwords"
        "browser.formfill.enable" = false; # Disable "Remember search and form history"
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.tabs.min_inactive_duration_before_unload" = 150000; # 2.5min (its ms)
        "browser.cache.memory.enable" = true;
        "browser.cache.memory.capacity" = 1048576;
        "browser.cache.memory.max_entry_size" = -1;
        "browser.cache.disk.enable" = false;
        "browser.cache.disk.smart_size.enabled" = false;

        # "sidebar.revamp" = false;
        "browser.urlbar.placeholderName" = "me";

        "keyword.enabled" = true;
        # "browser.search.suggest.enabled" = false;
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
        # "browser.fixup.alternate.enabled" = false;
      };
      #  https://addons.mozilla.org/api/v5/addons/search/?q=<extension-name> // Look for GUID
      ExtensionSettings = {
        "*" = {
          installation_mode = "blocked"; # block all except listed
        };
        # uBlock Origin [ublock-origin]
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        # Read Aloud [read-aloud]
        "{ddc62400-f22d-4dd3-8b4a-05837de53c2e}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/read-aloud/latest.xpi";
        };
        # Sidebery [sidebery]
        "{3c078156-979c-498b-8990-85f7987dd929}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
        };
        # ProtonPass [proton-pass]
        "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
        };
        # User-Agent Switcher []
        "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi";
        };
        # Auto Tab Discard [auto-tab-discard]
        "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/auto-tab-discard/latest.xpi";
        };
      };
    };
    # preferences = {};
    # preferencesStatus = "locked";
  };
}
