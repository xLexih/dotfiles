# Colors come from the theme (theme/base/targets/firefox). The profile lives
# at ~/.mozilla/firefox/default (home/.mozilla/firefox/profiles.ini) so
# home/.mozilla/firefox/default/chrome/userChrome.css can hide the tab bar
# for Sidebery.
let
  forceInstall = slug: {
    installation_mode = "force_installed";
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
  };
in {
  programs.firefox = {
    enable = true;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;

      Preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "accessibility.force_disabled" = 1;
        "browser.aboutConfig.showWarning" = false;
        "browser.formfill.enable" = false;
        "browser.newtabpage.activity-stream.feeds.recommendationprovider" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.tabs.closeWindowWithLastTab" = false;
        "browser.tabs.min_inactive_duration_before_unload" = 150000;
        "browser.vpn_promo.enabled" = false;
        "dom.ipc.processCount" = 4;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "extensions.pocket.enabled" = false;
        "findbar.highlightAll" = true;
        "layout.css.color-mix-multi-color.enabled" = true;
        "signon.autofillForms" = false;
        "signon.rememberSignons" = false;
        "widget.gtk.hide-pointer-while-typing.enabled" = false;
        "widget.wayland.fractional-scale.enabled" = false;

        # hardware video decoding
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "widget.dmabuf.force-enabled" = true;

        # cache in memory only
        "browser.cache.disk.enable" = false;
        "browser.cache.disk.smart_size.enabled" = false;
        "browser.cache.memory.capacity" = 1048576;
        "browser.cache.memory.enable" = true;
        "browser.cache.memory.max_entry_size" = -1;

        # address bar: search only, no suggestions
        "browser.urlbar.placeholderName" = "me";
        "browser.urlbar.suggest.addons" = false;
        "browser.urlbar.suggest.bookmark" = false;
        "browser.urlbar.suggest.history" = false;
        "browser.urlbar.suggest.openpage" = false;
        "browser.urlbar.suggest.recentsearches" = false;
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.suggest.topsites" = false;
        "browser.urlbar.suggest.trending" = false;
        "browser.urlbar.suggest.yelp" = false;
        "browser.urlbar.trimURLs" = false;
        "keyword.enabled" = true;
      };

      ExtensionSettings = {
        "firefox@tampermonkey.net" = forceInstall "tampermonkey";
        "uBlock0@raymondhill.net" = forceInstall "ublock-origin";
        "{ddc62400-f22d-4dd3-8b4a-05837de53c2e}" = forceInstall "read-aloud";
        "{3c078156-979c-498b-8990-85f7987dd929}" = forceInstall "sidebery";
        "78272b6fa58f4a1abaac99321d503a20@proton.me" = forceInstall "proton-pass";
        "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" = forceInstall "user-agent-string-switcher";
        "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}" = forceInstall "auto-tab-discard";
      };
    };
  };
}
