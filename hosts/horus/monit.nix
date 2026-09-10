# monit agent for horus — reports to the local M/Monit collector (./mmonit.nix).
{ ... }:
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
      matching = "mariadbd";
      restart = false;
    };
    phpfpm-librenms.matching = "phpfpm-librenms";
    nginx.matching = "nginx: master";
  };
}
