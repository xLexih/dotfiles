{ pkgs, nur, username, config, ... }: {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    profiles.default = {
      id = 0;
      name = username;
      isDefault = true;
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        read-aloud
        proton-pass
        tampermonkey # have to get licenses right
        sidebery
      ];
    };
  };
}

# This is an example of how the addons CAN be defined.
# allows for creationg custom ones.
# https://gitlab.com/rycee/nur-expressions/-/blob/master/pkgs/firefox-addons/generated-firefox-addons.nix?ref_type=heads#L9866
# "proton-pass" = buildFirefoxXpiAddon {
#   pname = "proton-pass";
#   version = "1.31.1";
#   addonId = "78272b6fa58f4a1abaac99321d503a20@proton.me";
#   url = "https://addons.mozilla.org/firefox/downloads/file/4474339/proton_pass-1.31.1.xpi";
#   sha256 = "1a5b44f5a3a3599af33ebc5307027682a951670ca7f797cc49cfd2a105db92ae";
#   meta = with lib;
#   {
#     homepage = "https://proton.me";
#     description = "Free and unlimited password manager to keep your login credentials safe and manage them directly in your browser.";
#     license = licenses.gpl3;
#     mozPermissions = [
#       "activeTab"
#       "alarms"
#       "scripting"
#       "storage"
#       "unlimitedStorage"
#       "webRequest"
#       "webRequestBlocking"
#       "https://*/*"
#       "http://*/*"
#       "https://account.proton.me/*"
#       "https://pass.proton.me/*"
#     ];
#     platforms = platforms.all;
#   };
# };
