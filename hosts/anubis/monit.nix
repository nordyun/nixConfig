# monit agent for anubis. Standalone for now — reports to the M/Monit collector
# on horus once that host exists (set myMonit.collector.enable = true).
#
# immich-server / nfs-server can be added to myMonit.processes once their
# process-match patterns are confirmed with `monit procmatch "<pat>"` on the box.
{ ... }:
{
  imports = [
    ../../modules/notify.nix
    ../../modules/monit.nix
  ];

  myMonit.processes = {
    jellyfin.matching = "jellyfin";
    mpd.matching = "mpd";
    samba-smbd.matching = "smbd";
    tailscaled.matching = "tailscaled";
  };
}
