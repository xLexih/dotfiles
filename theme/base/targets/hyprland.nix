# Themed screen-share picker for xdg-desktop-portal-hyprland. Window borders
# and shadows use {{theme.*}} placeholders in hyprland.lua instead.
{
  config,
  pkgs,
  ...
}: let
  theme = config.modules.theme.active;
  t = theme.palette // theme.roles;

  stylesheet = pkgs.writeText "share-picker.qss" ''
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

  picker = pkgs.writeShellScript "hyprland-share-picker-themed" ''
    export QT_STYLE_OVERRIDE=Fusion
    exec ${pkgs.xdg-desktop-portal-hyprland}/bin/hyprland-share-picker -stylesheet ${stylesheet}
  '';
in {
  dotfiles.files.".config/hypr/xdph.conf" = ''
    screencopy:custom_picker_binary = ${picker}
  '';
}
