# monit agent for thoth — local only for now (SMART health alerts via Slack).
#
# Collector reporting to M/Monit on horus (myMonit.collector.enable) and the
# `mercury` zpool check (myMonit.zpools) are deliberately left off: they need
# thoth's host key added to secrets/secrets.nix and a monit_control_thoth.age
# secret, per the TODO already in secrets.nix. Add those once thoth is fully
# onboarded, then set both here.
{ ... }:
{
  imports = [
    ../../modules/notify.nix
    ../../modules/monit.nix
  ];

  myMonit.smartHealth.enable = true;
}
