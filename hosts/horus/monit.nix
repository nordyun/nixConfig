# monit agent for horus.
#
# collector.enable stays false until the M/Monit collector (./mmonit.nix) is up
# and secrets/monit_collector.age is filled in — then flip it here and on
# neptune/anubis in one deploy.
{ ... }:
{
  imports = [
    ../../modules/notify.nix
    ../../modules/monit.nix
  ];

  # myMonit.collector.enable = true;

  myMonit.processes = {
    tailscaled.matching = "tailscaled";
    mmonit.matching = "bin/mmonit";
  };
}
