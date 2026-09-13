# monit agent for anubis — reports to the M/Monit collector on horus.
#
# immich-server / nfs-server can be added to myMonit.processes once their
# process-match patterns are confirmed with `monit procmatch "<pat>"` on the box.
{ ... }:
{
  imports = [
    ../../modules/notify.nix
    ../../modules/monit.nix
  ];

  myMonit.collector.enable = true;

  # Root is tmpfs on anubis (impermanence) - the baseline `check filesystem /`
  # doesn't watch anything that actually fills up. /persist holds real state;
  # /mercury is the ZFS pool root backing photos/movies/music/tv/nfs/samba.
  myMonit.extraFilesystems = {
    persist = "/persist";
  };
  myMonit.smartHealth.enable = true;

  myMonit.processes = {
    jellyfin.matching = "jellyfin";
    mpd.matching = "mpd";
    samba-smbd.matching = "smbd";
    tailscaled.matching = "tailscaled";
    snmpd.matching = "snmpd";
  };
}
