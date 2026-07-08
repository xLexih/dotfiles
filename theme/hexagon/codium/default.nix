{
  palette ? theme.ui,
  theme,
}: let
  manifest = builtins.fromJSON (builtins.readFile ./package.json);
  t = palette;
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
      "textLink.foreground" = t.link;
      "textLink.activeForeground" = t.accent;
      "editor.background" = t.bg;
      "editor.foreground" = t.fg;
      "editor.selectionBackground" = "${t.selectionBg}66";
      "editor.selectionForeground" = t.fg;
      "editor.inactiveSelectionBackground" = "${t.activeBg}80";
      "editor.selectionHighlightBackground" = "${t.selectionBg}30";
      "editor.wordHighlightBackground" = "${t.link}24";
      "editor.wordHighlightStrongBackground" = "${t.selectionBg}32";
      "editor.lineHighlightBackground" = t.surface;
      "editorCursor.foreground" = t.accent;
      "editorLineNumber.foreground" = t.fgMuted;
      "editorLineNumber.activeForeground" = t.accent;
      "editorGutter.background" = t.bgDark;
      "editorGutter.modifiedBackground" = t.yellow;
      "editorGutter.addedBackground" = t.green;
      "editorGutter.deletedBackground" = t.red;
      "editorIndentGuide.background1" = t.surface;
      "editorIndentGuide.activeBackground1" = t.overlay;
      "editorOverviewRuler.border" = t.overlay;
      "editorOverviewRuler.findMatchForeground" = t.yellow;
      "editorOverviewRuler.errorForeground" = t.red;
      "editorOverviewRuler.warningForeground" = t.yellow;
      "editorOverviewRuler.infoForeground" = t.blue;
      "editorWidget.background" = t.bgDark;
      "editorWidget.foreground" = t.fg;
      "editorWidget.border" = t.overlay;
      "editorSuggestWidget.background" = t.bgDark;
      "editorSuggestWidget.foreground" = t.fg;
      "editorSuggestWidget.border" = t.overlay;
      "editorSuggestWidget.highlightForeground" = t.accent;
      "editorSuggestWidget.selectedBackground" = t.activeBg;
      "editorHoverWidget.background" = t.bgDark;
      "editorHoverWidget.foreground" = t.fg;
      "editorHoverWidget.border" = t.overlay;
      "editor.findMatchBackground" = "${t.yellow}42";
      "editor.findMatchBorder" = t.yellow;
      "editor.findMatchHighlightBackground" = "${t.accentAlt}30";
      "editor.findRangeHighlightBackground" = "${t.surface}99";
      "editorBracketMatch.background" = "${t.accent}20";
      "editorBracketMatch.border" = t.accent;
      "editorError.foreground" = t.red;
      "editorWarning.foreground" = t.yellow;
      "editorInfo.foreground" = t.blue;
      "editorHint.foreground" = t.cyan;
      "editorUnnecessaryCode.opacity" = "#00000099";
      "sideBar.background" = t.bgDark;
      "sideBar.foreground" = t.fg;
      "sideBarTitle.foreground" = t.accent;
      "sideBarSectionHeader.background" = t.bgDarker;
      "sideBarSectionHeader.foreground" = t.accent;
      "sideBar.border" = t.overlay;
      "activityBar.background" = t.bgDarker;
      "activityBar.foreground" = t.accent;
      "activityBar.inactiveForeground" = t.fgMuted;
      "activityBarBadge.background" = t.accent;
      "activityBarBadge.foreground" = t.accentFg;
      "titleBar.activeBackground" = t.bgDark;
      "titleBar.activeForeground" = t.fg;
      "titleBar.inactiveBackground" = t.bgDarker;
      "titleBar.inactiveForeground" = t.fgMuted;
      "tab.activeBackground" = t.bg;
      "tab.activeForeground" = t.accent;
      "tab.inactiveBackground" = t.bgDark;
      "tab.inactiveForeground" = t.fgMuted;
      "tab.activeBorderTop" = t.accent;
      "tab.hoverBackground" = t.surface;
      "tab.border" = t.overlay;
      "editorGroupHeader.tabsBackground" = t.bgDark;
      "editorGroup.border" = t.overlay;
      "panel.background" = t.bgDark;
      "panel.border" = t.overlay;
      "panelTitle.activeForeground" = t.accent;
      "panelTitle.inactiveForeground" = t.fgMuted;
      "statusBar.background" = t.bgDarker;
      "statusBar.foreground" = t.fgMuted;
      "statusBar.debuggingBackground" = t.red;
      "statusBar.debuggingForeground" = t.dangerFg;
      "statusBar.noFolderBackground" = t.bgDarker;
      "statusBar.noFolderForeground" = t.fgMuted;
      "statusBarItem.remoteBackground" = t.accent;
      "statusBarItem.remoteForeground" = t.accentFg;
      "statusBarItem.hoverBackground" = t.surface;
      "terminal.background" = t.bg;
      "terminal.foreground" = t.fg;
      "terminal.selectionBackground" = "${t.selectionBg}66";
      "terminalCursor.foreground" = t.accent;
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
      "list.activeSelectionForeground" = t.fg;
      "list.hoverBackground" = t.surface;
      "list.inactiveSelectionBackground" = t.surface;
      "list.inactiveSelectionForeground" = t.fg;
      "list.inactiveFocusBackground" = t.surface;
      "list.focusBackground" = t.overlay;
      "list.highlightForeground" = t.accent;
      "list.errorForeground" = t.red;
      "list.warningForeground" = t.yellow;
      "tree.indentGuidesStroke" = t.overlay;
      "input.background" = t.inputBg;
      "input.foreground" = t.fg;
      "input.border" = t.overlay;
      "input.placeholderForeground" = t.fgMuted;
      "inputOption.activeBackground" = "${t.accent}30";
      "inputOption.activeBorder" = t.accent;
      "inputValidation.errorBackground" = t.bgDark;
      "inputValidation.errorBorder" = t.red;
      "inputValidation.warningBackground" = t.bgDark;
      "inputValidation.warningBorder" = t.yellow;
      "inputValidation.infoBackground" = t.bgDark;
      "inputValidation.infoBorder" = t.blue;
      "dropdown.background" = t.surface;
      "dropdown.foreground" = t.fg;
      "dropdown.border" = t.overlay;
      "menu.background" = t.bgDark;
      "menu.foreground" = t.fg;
      "menu.selectionBackground" = t.overlay;
      "menu.selectionForeground" = t.fg;
      "menu.separatorBackground" = t.overlay;
      "menu.border" = t.overlay;
      "button.background" = t.accent;
      "button.foreground" = t.accentFg;
      "button.hoverBackground" = t.accentBright;
      "button.secondaryBackground" = t.surface;
      "button.secondaryForeground" = t.fg;
      "button.secondaryHoverBackground" = t.overlay;
      "quickInput.background" = t.bgDark;
      "quickInput.foreground" = t.fg;
      "quickInputList.focusBackground" = t.overlay;
      "quickInputList.focusForeground" = t.fg;
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
      "gitDecoration.conflictingResourceForeground" = t.red;
      "gitDecoration.ignoredResourceForeground" = t.fgMuted;
      "badge.background" = t.accent;
      "badge.foreground" = t.accentFg;
      "peekView.border" = t.accent;
      "peekViewTitle.background" = t.bgDark;
      "peekViewTitleLabel.foreground" = t.fg;
      "peekViewTitleDescription.foreground" = t.fgMuted;
      "peekViewResult.background" = t.bgDark;
      "peekViewResult.selectionBackground" = t.overlay;
      "peekViewResult.selectionForeground" = t.fg;
      "peekViewEditor.background" = t.bg;
      "peekViewEditor.matchHighlightBackground" = "${t.yellow}36";
      "progressBar.background" = t.accent;
      "notificationCenterHeader.background" = t.bgDark;
      "notifications.background" = t.bg;
      "notifications.foreground" = t.fg;
      "notifications.border" = t.overlay;
      "notificationLink.foreground" = t.link;
      "notificationToast.border" = t.overlay;
      "problemsErrorIcon.foreground" = t.red;
      "problemsWarningIcon.foreground" = t.yellow;
      "problemsInfoIcon.foreground" = t.blue;
      "diffEditor.insertedTextBackground" = "${t.green}22";
      "diffEditor.removedTextBackground" = "${t.red}22";
      "diffEditor.insertedLineBackground" = "${t.green}14";
      "diffEditor.removedLineBackground" = "${t.red}14";
      "merge.currentHeaderBackground" = "${t.blue}28";
      "merge.incomingHeaderBackground" = "${t.green}28";
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
