{theme, ...}: {
  homeFiles = {
    ".mozilla/firefox/profiles.ini".text = theme.outputs.firefoxProfilesIni;
    ".mozilla/firefox/default/user.js".text = theme.outputs.firefoxUserJs;
    ".mozilla/firefox/default/chrome/userContent.css".text = theme.outputs.firefoxUserContent;
    ".mozilla/firefox/default/chrome/userChrome.css".text = theme.outputs.firefoxUserChrome;
  };
}
