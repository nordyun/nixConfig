# NUT netclient — same as hosts/neptune/nut.nix. thoth is on the same UPS as
# horus + neptune and shuts down cleanly on low battery.
#
# NOT yet imported in hosts/thoth/default.nix: do that once thoth is installed
# and its host key is added to `nut_remote_pw.age` recipients in
# secrets/secrets.nix (then `agenix -r`).
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
