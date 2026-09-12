{ ... }:
{
  imports = [
    ../../modules/notify.nix
    ../../modules/monit.nix
  ];

  myMonit.smartHealth.enable = true;
  myMonit.collector.enable = true;
  myMonit.zpools = [ "rpool" "mercury" ];
  myMonit.processes = {
    jellyfin.matching = "jellyfin";
    tailscaled.matching = "tailscaled";
    snmpd.matching = "snmpd";
  };
}
