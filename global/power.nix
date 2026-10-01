# Power profiles (performance, balanced, power-saver) over the standard D-Bus
# interface, switchable from the bar. Hosts that tune power with TLP get TLP's
# implementation of the interface; others use power-profiles-daemon.
{config, ...}: {
  services.tlp.pd.enable = config.services.tlp.enable;
  services.power-profiles-daemon.enable = !config.services.tlp.enable;
}
