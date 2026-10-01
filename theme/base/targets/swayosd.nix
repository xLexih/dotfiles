# On-screen display for volume and brightness (swayosd, GTK4 CSS). The server
# reads the stylesheet at startup, so a switch restarts it.
{pkgs, ...}: {
  modules.theme.reload.swayosd = "${pkgs.systemd}/bin/systemctl --user try-restart swayosd.service";

  modules.theme.render.swayosd = theme: let
    t = theme.palette // theme.roles;
  in {
    ".config/swayosd/style.css" = ''
      window#osd {
        border-radius: 999px;
        border: 2px solid ${t.borderStrong};
        background: alpha(${t.bg}, 0.92);
      }

      window#osd #container {
        margin: 14px 18px;
      }

      window#osd image,
      window#osd label {
        color: ${t.fg};
      }

      window#osd progressbar:disabled,
      window#osd image:disabled {
        opacity: 0.5;
      }

      window#osd progressbar,
      window#osd segmentedprogress {
        min-height: 6px;
        border-radius: 999px;
        background: transparent;
        border: none;
      }

      window#osd trough,
      window#osd segment {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: ${t.overlay};
      }

      window#osd progress,
      window#osd segment.active {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: ${t.accent};
      }

      window#osd segment {
        margin-left: 8px;
      }

      window#osd segment:first-child {
        margin-left: 0;
      }
    '';
  };
}
