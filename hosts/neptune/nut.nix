# NUT netclient — monitors the CyberPower on horus (netserver) over the tailnet.
# On low battery / FSD, neptune shuts down cleanly with the rest of the UPS'd
# hosts. Only upsmon runs here (no upsd, no driver).
#
# Uses horus's tailnet IP directly (not a name) — this is a safety path that
# must work even if neptune's unbound is mid-restart during a power event.
{ config, ... }:
{
  imports = [ ../../modules/nut.nix ];

  age.secrets.nut_remote_pw.file = ../../secrets/nut_remote_pw.age;

  power.ups = {
    enable = true;
    mode = "netclient";

    upsmon.monitor.cyberpower = {
      system = "cyberpower@100.86.167.115";
      user = "upsmon-remote";
      passwordFile = config.age.secrets.nut_remote_pw.path;
      type = "secondary";
    };
  };
}
