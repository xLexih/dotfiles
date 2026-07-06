{
  activeTheme,
  pkgs,
}: let
  forceInstall = slug: {
    installation_mode = "force_installed";
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
  };
in {
  enable = true;
  package = pkgs.firefox;

  policies = {
    DisableTelemetry = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DontCheckDefaultBrowser = true;
    NoDefaultBookmarks = true;
    Preferences = {
      "svg.context-properties.content.enabled" = true;
      "layout.css.color-mix-multi-color.enabled" = true;
      "widget.wayland.fractional-scale.enabled" = false;
      "widget.gtk.native-context-menus" = false;
      "dom.ipc.processCount" = 4;
      "media.ffmpeg.vaapi.enabled" = true;
      "media.hardware-video-decoding.force-enabled" = true;
      "widget.dmabuf.force-enabled" = true;
      "ui.systemUsesDarkTheme" = true;
      "ui.highlight" = activeTheme.ui.accent;
      "ui.highlighttext" = activeTheme.ui.bg;
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
      "firefox@tampermonkey.net" = forceInstall "tampermonkey";
      "uBlock0@raymondhill.net" = forceInstall "ublock-origin";
      "{ddc62400-f22d-4dd3-8b4a-05837de53c2e}" = forceInstall "read-aloud";
      "{3c078156-979c-498b-8990-85f7987dd929}" = forceInstall "sidebery";
      "78272b6fa58f4a1abaac99321d503a20@proton.me" = forceInstall "proton-pass";
      "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" = forceInstall "user-agent-string-switcher";
      "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}" = forceInstall "auto-tab-discard";
    };
  };
}
