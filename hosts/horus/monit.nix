# monit agent for horus. Standalone until the local M/Monit collector exists
# (Phase 1: add ./mmonit.nix, then set myMonit.collector.enable = true and grow
# myMonit.processes to cover mmonit / mariadbd / phpfpm-librenms / nginx /
# uptime-kuma / healthchecks / homepage-dashboard / upsd / upsmon / snmpd).
{ ... }:
{
  imports = [
    ../../modules/notify.nix
    ../../modules/monit.nix
  ];

  myMonit.processes = {
    tailscaled.matching = "tailscaled";
  };
}
