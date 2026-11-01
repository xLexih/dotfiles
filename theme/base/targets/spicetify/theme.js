// Follows theme switches: theme-colors.css links to the colors `theme` writes
// on every switch. When its contents change, they're applied on top of the
// stylesheet Spotify loaded at startup.
(() => {
  const url = "theme-colors.css";
  const style = document.createElement("style");
  let loaded;

  const check = async () => {
    let css;
    try {
      const response = await fetch(url, { cache: "no-store" });
      if (!response.ok) return;
      css = await response.text();
    } catch {
      return;
    }
    if (css !== loaded) {
      loaded = css;
      style.textContent = css;
      // Right after the link it replaces, so it wins the cascade like the link
      // did (Spicetify puts its style sheets at the end of <body>).
      if (!style.isConnected) {
        const link = document.querySelector(`link[href="${url}"]`);
        if (link) link.after(style);
        else document.body.append(style);
      }
    }
  };

  check();
  setInterval(check, 2000);
  window.addEventListener("focus", check);
})();
