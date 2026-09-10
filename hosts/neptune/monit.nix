# monit agent for neptune (router). Standalone for now — reports to the M/Monit
# collector on horus once that host exists (set myMonit.collector.enable = true).
{ ... }:
{
  imports = [
    ../../modules/notify.nix
    ../../modules/monit.nix
  ];

  myMonit.processes = {
    unbound.matching = "unbound";
    kea-dhcp4-server.matching = "kea-dhcp4";
    tailscaled.matching = "tailscaled";
  };
}
