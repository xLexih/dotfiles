# Firefox: a fixed "default" profile with themed userChrome/userContent CSS.
# Users append their own chrome CSS from their home layer.
{config, ...}: let
  theme = config.modules.theme.active;
  t = theme.palette // theme.roles;
  accent = "${t.accent}ee";
  fieldBg = "color-mix(in oklab, ${t.bg}, black 20%)";
in {
  programs.firefox.policies.Preferences = {
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "svg.context-properties.content.enabled" = true;
    "widget.gtk.native-context-menus" = false;
    "ui.systemUsesDarkTheme" = theme.variant == "dark";
    "ui.highlight" = t.selectionBg;
    "ui.highlighttext" = t.selectionFg;
  };

  dotfiles.files = {
    ".mozilla/firefox/profiles.ini" = ''
      [Profile0]
      Name=default
      IsRelative=1
      Path=default
      Default=1

      [General]
      StartWithLastProfile=1
      Version=2
    '';

    ".mozilla/firefox/default/chrome/userContent.css" = ''
      @-moz-document url-prefix("about:"), url-prefix("chrome://browser/content/") {
        :root {
          --in-content-page-background: ${t.bg} !important;
          --in-content-page-color: ${t.fg} !important;
          --in-content-primary-button-background: ${t.selectionBg} !important;
          --in-content-primary-button-text-color: ${t.selectionFg} !important;
          --in-content-accent-color: ${t.accent} !important;
          --in-content-box-background: ${t.bgDark} !important;
          --in-content-box-border-color: ${t.border} !important;
          --in-content-border-color: ${t.border} !important;
          --in-content-link-color: ${t.link} !important;
          --in-content-table-background: ${t.bgDark} !important;
          --in-content-item-hover: ${t.hoverBg} !important;
          --in-content-item-selected: ${t.activeBg} !important;
          --newtab-background-color: ${t.bg} !important;
          --newtab-background-color-secondary: ${t.bgDark} !important;
          --newtab-background-card: ${t.surface} !important;
          --newtab-text-primary-color: ${t.fg} !important;
          --newtab-primary-action-background: ${t.selectionBg} !important;
        }
      }

      /* Sidebery */
      #root {
        --color-accent-primary: ${accent} !important;
        --frame-bg: ${t.bg} !important;
        --frame-fg: var(--color-accent-primary) !important;
        --toolbar-fg: var(--frame-fg) !important;
        --toolbar-fg-active: var(--color-accent-primary) !important;
        --border: ${t.bg} !important;
        --notification-bg: ${t.bg} !important;
        --notification-fg: ${t.fg} !important;
        --ctx-menu-bg: ${t.bg} !important;
        --ctx-menu-fg: var(--color-accent-primary) !important;
        --ctx-menu-separator: ${t.border} !important;
        --popup-bg: ${t.bg} !important;
        --popup-fg: ${t.fg} !important;
        --tabs-normal-fg: color-mix(in oklab, ${accent}, transparent 35%) !important;
        --tabs-normal-bg: transparent !important;
        --tabs-activated-fg: var(--color-accent-primary) !important;
        --tabs-activated-bg: color-mix(in oklab, ${accent}, transparent 75%) !important;
        --tabs-progress-bg: var(--color-accent-primary) !important;
        --toolbar-bg: ${t.bg} !important;
        --nav-btn-accent: var(--color-accent-primary) !important;

        --s-accent: var(--color-accent-primary) !important;
        --s-frame-bg: ${t.bg} !important;
        --s-frame-fg: var(--color-accent-primary) !important;
        --s-toolbar-bg: ${t.bg} !important;
        --s-toolbar-fg: var(--color-accent-primary) !important;
        --s-toolbar-border: ${t.bg} !important;
        --s-popup-bg: ${t.bg} !important;
        --s-popup-fg: ${t.fg} !important;
        --s-popup-border: ${t.border} !important;
        --s-act-el-bg: color-mix(in oklab, ${accent}, transparent 75%) !important;
        --s-act-el-fg: var(--color-accent-primary) !important;
        --s-act-el-border: var(--color-accent-primary) !important;
      }
    '';

    ".mozilla/firefox/default/chrome/userChrome.css" = ''
      :root {
        --chrome-selection-color: ${t.selectionFg} !important;
        --chrome-selection-background-color: ${t.selectionBg} !important;
        --toolbar-bgcolor: ${t.bg} !important;
        --lwt-accent-color: ${t.bg} !important;
        --lwt-text-color: ${t.fg} !important;
        --lwt-toolbar-field-background-color: ${fieldBg} !important;
        --lwt-toolbar-field-color: ${t.fg} !important;
        --lwt-toolbar-field-focus-color: ${t.fg} !important;
        --lwt-toolbar-field-border-color: ${t.border} !important;
        --lwt-toolbar-field-highlight: ${t.selectionBg} !important;
        --lwt-toolbar-field-highlight-text: ${t.selectionFg} !important;
        --color-accent-primary: ${accent} !important;
        --color-accent-primary-hover: ${accent} !important;
        --color-accent-primary-active: ${accent} !important;
        --focus-outline-color: var(--color-accent-primary) !important;
        --border-color-selected: var(--color-accent-primary) !important;
        --toolbar-color: var(--color-accent-primary) !important;
        --toolbar-background-color: ${t.bg} !important;
        --toolbox-background-color: ${t.bg} !important;
        --toolbox-text-color: var(--color-accent-primary) !important;
        --toolbox-text-color-inactive: color-mix(in oklab, var(--color-accent-primary), transparent 35%) !important;
        --toolbarbutton-icon-fill: var(--color-accent-primary) !important;
        --toolbarbutton-icon-fill-attention: var(--color-accent-primary) !important;
        --toolbarbutton-background-color-hover: color-mix(in oklab, var(--color-accent-primary), transparent 88%) !important;
        --toolbarbutton-background-color-active: color-mix(in oklab, var(--color-accent-primary), transparent 75%) !important;
        --toolbarbutton-outline-color-hover: color-mix(in oklab, var(--color-accent-primary), transparent 45%) !important;
        --toolbarbutton-outline-color-active: var(--color-accent-primary) !important;
        --toolbarbutton-outline-color-selected: var(--color-accent-primary) !important;
        --toolbar-field-background-color: ${fieldBg} !important;
        --toolbar-field-focus-background-color: ${fieldBg} !important;
        --toolbar-field-border-color: ${t.border} !important;
        --toolbar-field-border-color-focus: var(--color-accent-primary) !important;
        --toolbar-field-color: ${t.fg} !important;
        --toolbar-field-focus-color: ${t.fg} !important;
        --toolbar-field-text-color: ${t.fg} !important;
        --toolbar-field-text-color-focus: ${t.fg} !important;
        --urlbar-box-background-color: ${fieldBg} !important;
        --urlbar-box-background-color-focus: ${fieldBg} !important;
        --urlbar-box-background-color-hover: ${t.hoverBg} !important;
        --urlbar-box-background-color-active: ${t.activeBg} !important;
        --urlbar-box-text-color: ${t.fg} !important;
        --urlbar-box-text-color-hover: ${t.fg} !important;
        --urlbar-box-bgcolor: ${fieldBg} !important;
        --urlbarview-background-color-hover: color-mix(in oklab, var(--color-accent-primary), transparent 80%) !important;
        --urlbarview-background-color-selected: color-mix(in oklab, var(--color-accent-primary), transparent 50%) !important;
        --urlbarview-text-color-selected: ${t.selectionFg} !important;
        --urlbarview-text-color-action: var(--color-accent-primary) !important;
        --urlbarview-separator-color: ${t.border} !important;
        --urlbarView-secondary-text-color: color-mix(in oklab, var(--color-accent-primary), transparent 35%) !important;
        --link-color: ${t.link} !important;
        --chrome-content-separator-color: var(--color-accent-primary) !important;
        --arrowpanel-border-color: var(--color-accent-primary) !important;
        --arrowpanel-background: ${t.bg} !important;
        --arrowpanel-color: ${t.fg} !important;
        --arrowpanel-dimmed: ${t.hoverBg} !important;
        --arrowpanel-dimmed-further: ${t.activeBg} !important;
        --panel-background: ${t.bg} !important;
        --panel-background-color: ${t.bg} !important;
        --panel-color: ${t.fg} !important;
        --panel-text-color: ${t.fg} !important;
        --panel-border-color: ${t.border} !important;
        --panel-separator-color: ${t.border} !important;
        --panel-description-color: color-mix(in oklab, ${t.fg}, transparent 30%) !important;
        --panel-item-hover-bgcolor: ${t.hoverBg} !important;
        --panel-item-active-bgcolor: ${t.activeBg} !important;
        --panel-item-hover-color: ${t.fg} !important;
        --panel-item-active-color: ${t.fg} !important;
        --menu-background-color: ${t.bg} !important;
        --menu-color: ${t.fg} !important;
        --menuitem-hover-background-color: ${t.hoverBg} !important;
        --menuitem-disabled-hover-background-color: transparent !important;
        --menuitem-icon-fill: var(--color-accent-primary) !important;
        --text-color-disabled: color-mix(in oklab, ${t.fg}, transparent 55%) !important;
        --button-background-color: ${t.surface} !important;
        --button-background-color-hover: ${t.activeBg} !important;
        --button-background-color-active: color-mix(in oklab, var(--color-accent-primary), transparent 70%) !important;
        --button-text-color: ${t.fg} !important;
        --button-text-color-primary: ${t.selectionFg} !important;
        --input-bgcolor: ${fieldBg} !important;
        --input-color: ${t.fg} !important;
        --input-border-color: ${t.border} !important;
        --sidebar-background-color: ${t.bg} !important;
        --sidebar-text-color: ${t.fg} !important;
        --sidebar-border-color: ${t.bg} !important;
        --toolbarbutton-special-border-radius: 0px 0px 15px 15px / 15px !important;

        --s-frame-bg: ${t.bg} !important;
        --s-border: ${t.bg} !important;
        --s-notification-bg: ${t.bg} !important;
        --s-ctx-menu-bg: ${t.bg} !important;
        --s-ctx-menu-separator: ${t.bg} !important;
        --s-popup-bg: ${t.bg} !important;
        --s-toolbar-bg: ${t.bg} !important;
        --s-tabs-activated-bg: color-mix(in oklab, var(--color-accent-primary), transparent 75%) !important;
      }

      #navigator-toolbox,
      #titlebar,
      #toolbar-menubar,
      #TabsToolbar,
      #nav-bar,
      #PersonalToolbar,
      toolbar.browser-toolbar {
        background-color: ${t.bg} !important;
        background-image: none !important;
        color: ${t.fg} !important;
      }

      .urlbar-icon,
      .toolbarbutton-icon,
      .searchbar-engine-one-off-item :is(image, .button-icon),
      .urlbarView-button,
      .urlbarView-action-btn {
        fill: var(--color-accent-primary) !important;
        -moz-context-properties: fill, fill-opacity !important;
      }

      .urlbar-input {
        color: ${t.fg} !important;
      }

      .urlbar-background,
      #urlbar:is([focused], [open]) > .urlbar-background,
      #searchbar,
      #searchbar:focus-within,
      #searchbar-new > .urlbar-background {
        background-color: ${fieldBg} !important;
        border-color: var(--toolbar-field-border-color-focus) !important;
        box-shadow: none !important;
      }

      #urlbar:is([focused], [open]) > .urlbar-input-container,
      #searchbar:focus-within,
      #searchbar-new:is([focused], [open]) > .urlbar-input-container {
        color: ${t.fg} !important;
      }

      .urlbarView-row:is([selected], [row-selectable]:hover),
      .urlbarView-realtime-root:not([selectable]) > .urlbarView-realtime-item:hover,
      .urlbarView-realtime-item[selected] {
        background-color: color-mix(in oklab, ${t.selectionBg}, transparent 35%) !important;
      }

      .urlbarView-row:is([selected], [row-selectable]:hover) :is(
        .urlbarView-title,
        .urlbarView-url,
        .urlbarView-action,
        .urlbarView-explanation,
        .urlbarView-row-body-description,
        .urlbarView-row-body-bottom,
        .urlbarView-overflowable
      ),
      .urlbarView-realtime-item:is(:hover, [selected]) :is(
        .urlbarView-realtime-description-top,
        .urlbarView-realtime-description-bottom
      ) {
        color: ${t.selectionFg} !important;
      }

      #urlbar:is([focused], [open])[breakout-extend] > .urlbar-background {
        border-radius: var(--toolbarbutton-special-border-radius) !important;
      }

      #statuspanel-label {
        background-color: var(--color-accent-primary) !important;
        color: ${t.selectionFg} !important;
      }

      menupopup,
      panel {
        --panel-background: ${t.bg} !important;
        --panel-background-color: ${t.bg} !important;
        --panel-color: ${t.fg} !important;
        --panel-text-color: ${t.fg} !important;
        --panel-border-color: ${t.border} !important;
        --panel-separator-color: ${t.border} !important;
        --panel-box-shadow: 0 4px 14px ${t.shadow} !important;
        --menuitem-icon-fill: var(--color-accent-primary) !important;
        --menuitem-border-radius: 4px !important;
        --menuitem-padding: 0.45em 0.85em !important;
      }

      menupopup {
        --background-color-canvas: ${t.bg} !important;
        appearance: none !important;
        background: ${t.bg} !important;
        background-color: ${t.bg} !important;
        color: ${t.fg} !important;
        border: 1px solid ${t.border} !important;
        box-shadow: 0 4px 12px ${t.shadow} !important;
      }

      menupopup::part(content),
      panel::part(content) {
        background: ${t.bg} !important;
        background-color: ${t.bg} !important;
        color: ${t.fg} !important;
        border-color: ${t.border} !important;
        box-shadow: 0 4px 14px ${t.shadow} !important;
      }

      menuitem,
      menu,
      menucaption {
        appearance: none !important;
        background-color: transparent !important;
        color: ${t.fg} !important;
        fill: var(--color-accent-primary) !important;
      }

      :is(menuitem, menu):is(:hover, [_moz-menuactive="true"], [selected="true"]):not([disabled="true"]) {
        appearance: none !important;
        background-color: ${t.hoverBg} !important;
        color: ${t.fg} !important;
      }

      :is(menuitem, menu)[disabled="true"],
      :is(menuitem, menu)[disabled="true"] > :is(.menu-text, .menu-accel) {
        color: color-mix(in oklab, ${t.fg}, transparent 55%) !important;
      }

      .menu-icon,
      .menu-accel,
      menupopup > menu::after {
        fill: var(--color-accent-primary) !important;
        color: var(--color-accent-primary) !important;
      }

      menuseparator,
      toolbarseparator {
        border-color: ${t.border} !important;
      }
    '';
  };
}
