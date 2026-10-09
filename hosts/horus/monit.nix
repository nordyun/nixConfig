# monit agent for horus — reports to the local M/Monit collector (./mmonit.nix).
{ pkgs, ... }:
{
  imports = [
    ../../modules/notify.nix
    ../../modules/monit.nix
  ];

  myMonit.collector.enable = true;

  myMonit.processes = {
    tailscaled.matching = "tailscaled";
    mmonit.matching = "bin/mmonit";
    upsd.matching = "upsd";
    upsmon.matching = "upsmon";
    upsdrv.matching = "usbhid-ups";
    snmpd.matching = "snmpd";
    mysql = {
      # NixOS invokes the `mysqld` compat name; alternation future-proofs it
      matching = "bin/(mysqld|mariadbd)";
      restart = false;
    };
    phpfpm-librenms.matching = "phpfpm-librenms";
    nginx.matching = "nginx: master";
  };
  myMonit.extraConfig = ''
    check host heimdall-kuma with address heimdall.taila3fef.ts.net
      if failed
        port 10443
        protocol https
        request "/dashboard"
        status = 200
        with timeout 15 seconds
      for 3 cycles
      then exec "${pkgs.writeShellScript "heimdall-kuma-down" ''
        exec /run/current-system/sw/bin/notify alert \
          "Heimdall Kuma unreachable" \
          "Horus cannot reach Heimdall's Kuma HTTPS endpoint."
      ''}"
      else if succeeded
      then exec "${pkgs.writeShellScript "heimdall-kuma-up" ''
        exec /run/current-system/sw/bin/notify info \
          "Heimdall Kuma recovered" \
          "Horus can reach Heimdall's Kuma HTTPS endpoint again."
      ''}"
  '';
}
