# monit agent for neptune (router) — reports to the M/Monit collector on horus.
{ ... }:
{
  imports = [
    ../../modules/notify.nix
    ../../modules/monit.nix
  ];

  myMonit.collector.enable = true;

  myMonit.processes = {
    unbound.matching = "unbound";
    kea-dhcp4-server.matching = "kea-dhcp4";
    tailscaled.matching = "tailscaled";
  };
}
