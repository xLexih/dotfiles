# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/firefox.nix
# https://gitlab.com/scientiac/tesseract.home.manager/-/blob/main/apps/graphical/firefox/default.nix#L9
{
  config,
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

  config.hjem.users = lib.attrsets.genAttrs settings.users (username: {
    files = {
      ".mozilla/firefox/default/chrome/userChrome.css".text = ''
        /* hides the tabs and the left useless part */
        #TabsToolbar,
        #sidebar-header,
        #sidebar-splitter {
          display: none !important;
        }
        /*  The whole nab bar including the right button */
        #nav-bar-customization-target,
        #PanelUI-button {
          background-color: #2a1144dd !important;
        }

        /*  The extended section of the search bar */
        #urlbar:is([focused], [open]) > #urlbar-background,
        #searchbar:focus-within {
          /* background-color: #110022aa !important; */
          background-color: rgba(17, 0, 34, 0.67) !important;
          backdrop-filter: blur(1.5px) !important;
        }

        /* Add rounding once the breakout is extended. */
        #urlbar:is([focused], [open])[breakout-extend] > #urlbar-background {
          border-radius: 0px 0px 15px 15px / 15px !important; /* Bottom rounding */
        }

        /*  Targets the selection in search bar   */
        #urlbar[focused]:not([suppress-focus-border]) > #urlbar-background,
        #searchbar:focus-within,
        .searchbar-engine-one-off-item[selected]
        {
          outline-color: #dbb0ffee !important;
        }

        .searchbar-engine-one-off-item[selected] {
          background-color: #dbb0ffaa !important;
        }
        .urlbarView-row {
          &[selected] {
            background-color: #dbb0ff60 !important;
          }
        }
      '';
    };
  });

  config.programs.firefox = {
    enable = true;
    package = inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin; # The official firefox binary. did it to add blur()
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
        "app.shield.optoutstudies.enabled" = false;
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";

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

        "sidebar.revamp" = false;
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

        "services.sync.prefs.sync.browser.urlbar.suggest.bookmark" = false;
        "services.sync.prefs.sync.browser.urlbar.suggest.history" = false;
        "services.sync.prefs.sync.browser.urlbar.suggest.topsites" = false;
        "services.sync.prefs.sync.browser.urlbar.suggest.searches" = false;
        "services.sync.prefs.sync.browser.urlbar.suggest.openpages" = false;

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
