# M/Monit collector. The vendor binary chdir()s to its install root and writes
# db/ logs/ conf/license.xml relative to it, so it can't run from the read-only
# store: an ExecStartPre seeds a writable copy in the StateDirectory (refreshing
# the program dirs every start so package upgrades take effect, keeping db/ conf/
# logs/ across restarts) and mmonit runs from there.
#
# First start fetches a 30-day trial license from mmonit.com:443 -> conf/license.xml.
# GUI + collector endpoint on :8080 (tailnet only). Default login admin/swordfish
# -> change it, then create/set the collector user's password to match
# secrets/monit_collector.age.
{
  pkgs,
  lib,
  config,
  ...
}:
let
  mmonit = pkgs.callPackage ../../pkgs/mmonit { };

  seed = pkgs.writeShellScript "mmonit-seed" ''
    set -eu
    state=/var/lib/mmonit
    src=${mmonit}/libexec/mmonit

    # refresh read-only program dirs every start (picks up package upgrades)
    for d in bin lib docroot doc upgrade; do
      rm -rf "$state/$d"
      cp -a "$src/$d" "$state/$d"
    done
    cp -f "$src/README" "$state/README"

    # seed writable state once
    mkdir -p "$state/logs"
    if [ ! -e "$state/db/mmonit.db" ]; then
      mkdir -p "$state/db"
      cp -a "$src/db/." "$state/db/"
    fi
    if [ ! -e "$state/conf/server.xml" ]; then
      mkdir -p "$state/conf"
      cp -a "$src/conf/." "$state/conf/"
    fi
    chmod -R u+rwX "$state"
  '';

  start = pkgs.writeShellScript "mmonit-start" ''
    exec /var/lib/mmonit/bin/mmonit -i -c /var/lib/mmonit/conf/server.xml
  '';
in
{
  users.users.mmonit = {
    isSystemUser = true;
    group = "mmonit";
    home = "/var/lib/mmonit";
  };
  users.groups.mmonit = { };

  systemd.services.mmonit = {
    description = "M/Monit collector";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "mmonit";
      Group = "mmonit";
      StateDirectory = "mmonit";
      StateDirectoryMode = "0700";
      WorkingDirectory = "/var/lib/mmonit";
      ExecStartPre = seed;
      ExecStart = start;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # GUI + agent collector endpoint, tailnet only
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8080 ];
}
