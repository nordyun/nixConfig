# NUT server — the CyberPower CP1500PFCRM2U is on horus's USB (usbhid-ups).
#
# mode = "netserver": upsd is reachable over the tailnet so neptune + thoth run
# as netclients (mode = "netclient") and shut down cleanly alongside horus when
# the battery runs low. Shutdown order: secondaries first, then horus (primary),
# then the UPS cuts power (ups.delay.shutdown).
#
# upsd listens on 0.0.0.0:3493 but horus's firewall only trusts tailscale0
# (hosts/horus/tailscale.nix), so it's tailnet-only in practice. Reads need no
# auth; the MONITOR relationship needs the upsmon / upsmon-remote passwords.
{ config, ... }:
{
  imports = [ ../../modules/nut.nix ];

  age.secrets.nut_upsmon_pw.file = ../../secrets/nut_upsmon_pw.age;
  age.secrets.nut_remote_pw.file = ../../secrets/nut_remote_pw.age;

  power.ups = {
    enable = true;
    mode = "netserver";

    ups.cyberpower = {
      driver = "usbhid-ups";
      port = "auto";
      description = "CyberPower CP1500PFCRM2U";
    };

    upsd.listen = [ { address = "0.0.0.0"; } ];

    users.upsmon = {
      passwordFile = config.age.secrets.nut_upsmon_pw.path;
      upsmon = "primary";
    };
    users.upsmon-remote = {
      passwordFile = config.age.secrets.nut_remote_pw.path;
      upsmon = "secondary";
    };

    upsmon.monitor.cyberpower = {
      user = "upsmon";
      type = "primary";
      # passwordFile defaults to users.upsmon.passwordFile
    };
  };
}
