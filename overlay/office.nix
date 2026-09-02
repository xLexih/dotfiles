final: prev: {
  office-suite = prev.symlinkJoin {
    name = "office-suite";
    paths = with prev; [
      onlyoffice-desktopeditors # document editor
      libreoffice-qt-stable # full office suite
      zotero # reference manager
    ];
  };
}
