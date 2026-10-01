# Hyprland: border and shadow colors plus cursor in ~/.config/hypr/theme.lua,
# which hyprland.lua loads at startup and `theme` re-runs on a switch. Also the
# stylesheet of the screen-share picker, read each time it opens.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (import ../lib.nix {inherit lib;}) hex;
  hyprctl = "${config.programs.hyprland.package}/bin/hyprctl";
  rgba = alpha: color: "rgba(${hex color}${alpha})";

  render = theme: let
    t = theme.colors;
  in {
    ".config/hypr/theme.lua" = ''
      hl.env("XCURSOR_THEME", "${theme.cursor.name}")
      hl.env("XCURSOR_SIZE", "${toString theme.cursor.size}")
      hl.env("HYPRCURSOR_THEME", "${theme.cursor.name}")
      hl.env("HYPRCURSOR_SIZE", "${toString theme.cursor.size}")

      hl.config({
          general = {
              col = {
                  active_border = { colors = { "${rgba "ee" t.accent}", "${rgba "ee" t.accentBright}" }, angle = 45 },
                  inactive_border = "${rgba "aa" t.overlay}",
              },
          },
          decoration = { shadow = { color = "${rgba "ee" t.shadow}" } },
      })
    '';

    ".config/hypr/share-picker.qss" = ''
      QWidget {
        background-color: ${t.bg};
        color: ${t.fg};
        selection-background-color: ${t.selectionBg};
        selection-color: ${t.selectionFg};
      }
      QLabel {
        color: ${t.fg};
      }
      QFrame, QGroupBox {
        border-color: ${t.border};
      }
      QLineEdit, QComboBox, QListView, QTreeView {
        background-color: ${t.inputBg};
        color: ${t.fg};
        border: 1px solid ${t.border};
        border-radius: 6px;
        padding: 5px 8px;
        selection-background-color: ${t.selectionBg};
        selection-color: ${t.selectionFg};
      }
      QLineEdit:focus, QComboBox:focus, QListView:focus, QTreeView:focus {
        border-color: ${t.focus};
      }
      QListView::item, QTreeView::item {
        min-height: 24px;
        padding: 4px 8px;
      }
      QListView::item:hover, QTreeView::item:hover {
        background-color: ${t.hoverBg};
      }
      QListView::item:selected, QTreeView::item:selected {
        background-color: ${t.selectionBg};
        color: ${t.selectionFg};
      }
      QPushButton {
        background-color: ${t.surface};
        color: ${t.fg};
        border: 1px solid ${t.border};
        border-radius: 6px;
        padding: 6px 16px;
      }
      QPushButton:hover {
        background-color: ${t.hoverBg};
        border-color: ${t.borderStrong};
      }
      QPushButton:pressed, QPushButton:checked {
        background-color: ${t.selectionBg};
        color: ${t.selectionFg};
        border-color: ${t.selectionBg};
      }
      QPushButton:disabled {
        color: ${t.disabledFg};
        border-color: ${t.border};
      }
    '';
  };

  picker = pkgs.writeShellScript "hyprland-share-picker-themed" ''
    export QT_STYLE_OVERRIDE=Fusion
    exec ${pkgs.xdg-desktop-portal-hyprland}/bin/hyprland-share-picker -stylesheet "$HOME/.config/hypr/share-picker.qss"
  '';
in {
  modules.theme.render.hyprland = render;

  modules.theme.reload.hyprland = ''
    ${hyprctl} eval "dofile(\"$HOME/.config/hypr/theme.lua\")"
    ${hyprctl} setcursor "$(theme_get .cursor.name)" "$(theme_get .cursor.size)"
  '';

  dotfiles.files.".config/hypr/xdph.conf" = ''
    screencopy:custom_picker_binary = ${picker}
  '';
}
