{theme}: let
  manifest = builtins.fromJSON (builtins.readFile ./package.json);
  t = theme.ui;
in {
  inherit (manifest) name publisher version;
  manifestPath = ./package.json;
  themeFileName = "bestagon-purple.json";
  uniqueId = "${manifest.publisher}.${manifest.name}";
  packageName = "vscode-extension-${manifest.name}";

  themeJson = builtins.toJSON {
    name = "Bestagon Purple";
    type = "dark";
    colors = {
      "foreground" = t.fg;
      "descriptionForeground" = t.fgMuted;
      "icon.foreground" = t.fgMuted;
      "disabledForeground" = "${t.fgMuted}60";
      "focusBorder" = t.accent;
      "selection.background" = t.overlay;
      "widget.shadow" = t.shadow;
      "textLink.foreground" = t.accentAlt;
      "textLink.activeForeground" = t.accent;
      "editor.background" = t.bg;
      "editor.foreground" = t.fg;
      "editor.selectionBackground" = t.overlay;
      "editor.lineHighlightBackground" = t.surface;
      "editorCursor.foreground" = t.accent;
      "editorLineNumber.foreground" = t.fgMuted;
      "editorLineNumber.activeForeground" = t.accent;
      "editorGutter.background" = t.bgDark;
      "editorIndentGuide.background1" = t.surface;
      "editorIndentGuide.activeBackground1" = t.overlay;
      "editorOverviewRuler.border" = t.overlay;
      "editorWidget.background" = t.bgDark;
      "editorWidget.foreground" = t.fg;
      "editorWidget.border" = t.overlay;
      "sideBar.background" = t.bgDark;
      "sideBar.foreground" = t.fg;
      "sideBarTitle.foreground" = t.accent;
      "sideBarSectionHeader.background" = t.bgDarker;
      "sideBarSectionHeader.foreground" = t.accent;
      "activityBar.background" = t.bgDarker;
      "activityBar.foreground" = t.accent;
      "titleBar.activeBackground" = t.bgDark;
      "titleBar.activeForeground" = t.fg;
      "tab.activeBackground" = t.bg;
      "tab.activeForeground" = t.accent;
      "tab.inactiveBackground" = t.bgDark;
      "tab.inactiveForeground" = t.fgMuted;
      "tab.activeBorderTop" = t.accent;
      "editorGroupHeader.tabsBackground" = t.bgDark;
      "panel.background" = t.bgDark;
      "panel.border" = t.overlay;
      "statusBar.background" = t.bgDarker;
      "statusBar.foreground" = t.fgMuted;
      "statusBar.debuggingBackground" = t.red;
      "statusBar.debuggingForeground" = t.bg;
      "terminal.background" = t.bg;
      "terminal.foreground" = t.fg;
      "terminal.ansiBlack" = t.bg;
      "terminal.ansiRed" = t.red;
      "terminal.ansiGreen" = t.green;
      "terminal.ansiYellow" = t.yellow;
      "terminal.ansiBlue" = t.blue;
      "terminal.ansiMagenta" = t.accent;
      "terminal.ansiCyan" = t.cyan;
      "terminal.ansiWhite" = t.fg;
      "terminal.ansiBrightBlack" = t.overlay;
      "terminal.ansiBrightRed" = t.red;
      "terminal.ansiBrightGreen" = t.green;
      "terminal.ansiBrightYellow" = t.yellow;
      "terminal.ansiBrightBlue" = t.blue;
      "terminal.ansiBrightMagenta" = t.accentBright;
      "terminal.ansiBrightCyan" = t.cyan;
      "terminal.ansiBrightWhite" = "#ffffff";
      "list.activeSelectionBackground" = t.overlay;
      "list.hoverBackground" = t.surface;
      "list.inactiveSelectionBackground" = t.surface;
      "list.inactiveFocusBackground" = t.surface;
      "list.focusBackground" = t.overlay;
      "list.highlightForeground" = t.accent;
      "tree.indentGuidesStroke" = t.overlay;
      "input.background" = t.surface;
      "input.foreground" = t.fg;
      "input.border" = t.overlay;
      "dropdown.background" = t.surface;
      "dropdown.foreground" = t.fg;
      "menu.background" = t.bgDark;
      "menu.foreground" = t.fg;
      "menu.selectionBackground" = t.overlay;
      "menu.selectionForeground" = t.fg;
      "menu.separatorBackground" = t.overlay;
      "menu.border" = t.overlay;
      "quickInput.background" = t.bgDark;
      "quickInput.foreground" = t.fg;
      "commandCenter.background" = t.bgDark;
      "commandCenter.foreground" = t.fg;
      "commandCenter.border" = t.overlay;
      "keybindingLabel.background" = t.surface;
      "keybindingLabel.foreground" = t.fg;
      "keybindingLabel.border" = t.overlay;
      "breadcrumb.background" = t.bgDark;
      "breadcrumb.foreground" = t.fgMuted;
      "breadcrumb.focusForeground" = t.accent;
      "breadcrumb.activeSelectionForeground" = t.fg;
      "scrollbarSlider.background" = "${t.overlay}80";
      "scrollbarSlider.hoverBackground" = "${t.overlay}b0";
      "scrollbarSlider.activeBackground" = "${t.accent}60";
      "minimap.background" = t.bgDark;
      "gitDecoration.modifiedResourceForeground" = t.yellow;
      "gitDecoration.untrackedResourceForeground" = t.green;
      "gitDecoration.deletedResourceForeground" = t.red;
      "badge.background" = t.accent;
      "badge.foreground" = t.bg;
      "peekView.border" = t.accent;
      "peekViewTitle.background" = t.bgDark;
      "peekViewResult.background" = t.bgDark;
      "peekViewEditor.background" = t.bg;
      "progressBar.background" = t.accent;
      "notificationCenterHeader.background" = t.bgDark;
      "notifications.background" = t.bg;
      "notifications.foreground" = t.fg;
    };
    tokenColors = [
      {
        scope = ["comment" "punctuation.definition.comment"];
        settings = {
          foreground = t.fgMuted;
          fontStyle = "italic";
        };
      }
      {
        scope = ["string" "string.quoted"];
        settings = {foreground = t.green;};
      }
      {
        scope = ["constant.numeric" "constant.language"];
        settings = {foreground = t.yellow;};
      }
      {
        scope = ["keyword" "storage.type" "storage.modifier"];
        settings = {foreground = t.accent;};
      }
      {
        scope = ["entity.name.function" "support.function"];
        settings = {foreground = t.blue;};
      }
      {
        scope = ["entity.name.type" "entity.name.class" "support.type"];
        settings = {foreground = t.yellow;};
      }
      {
        scope = ["variable" "variable.other"];
        settings = {foreground = t.fg;};
      }
      {
        scope = ["variable.parameter"];
        settings = {foreground = t.red;};
      }
      {
        scope = ["entity.name.tag"];
        settings = {foreground = t.red;};
      }
      {
        scope = ["entity.other.attribute-name"];
        settings = {foreground = t.yellow;};
      }
      {
        scope = ["punctuation" "meta.brace"];
        settings = {foreground = t.fgMuted;};
      }
      {
        scope = ["constant.other" "support.constant"];
        settings = {foreground = t.cyan;};
      }
      {
        scope = ["meta.decorator" "punctuation.decorator"];
        settings = {foreground = t.accentBright;};
      }
      {
        scope = ["markup.heading"];
        settings = {
          foreground = t.accent;
          fontStyle = "bold";
        };
      }
      {
        scope = ["markup.bold"];
        settings = {fontStyle = "bold";};
      }
      {
        scope = ["markup.italic"];
        settings = {fontStyle = "italic";};
      }
      {
        scope = ["markup.inline.raw"];
        settings = {foreground = t.cyan;};
      }
    ];
  };
}
