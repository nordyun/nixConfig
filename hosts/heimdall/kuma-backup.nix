{ config, pkgs, ... }:
let
  exportBackup = pkgs.writeShellApplication {
    name = "kuma-backup-export";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.rsync pkgs.sqlite pkgs.gnutar pkgs.gzip pkgs.util-linux ];
    text = ''
      if (( $# != 0 )); then
        echo "kuma-backup-export takes no arguments" >&2
        exit 1
      fi
      umask 077
      exec 9>/run/kuma-backup-export.lock
      flock -w 60 9
      scratch=$(mktemp -d /run/kuma-backup.XXXXXX)
      trap 'rm -rf -- "$scratch"' EXIT
      mkdir "$scratch/state"

      # Static assets/config accompany a consistent online SQLite backup.
      # The live WAL/SHM files must not overwrite that standalone database.
      rsync -a --exclude='/kuma.db' --exclude='/kuma.db-wal' \
        --exclude='/kuma.db-shm' --exclude='/kuma.db-journal' \
        /var/lib/uptime-kuma/ "$scratch/state/"
      sqlite3 -readonly /var/lib/uptime-kuma/kuma.db \
        '.timeout 60000' ".backup '$scratch/state/kuma.db'"
      [[ $(sqlite3 -readonly "$scratch/state/kuma.db" 'PRAGMA quick_check;') == ok ]]
      printf '%s\n' '${config.services.uptime-kuma.package.version}' > "$scratch/KUMA_VERSION"
      date -u +%FT%TZ > "$scratch/BACKUP_TIME"
      cd "$scratch"
      find state -type f -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
      tar --numeric-owner -czf - state KUMA_VERSION BACKUP_TIME SHA256SUMS
    '';
  };
in
{
  environment.systemPackages = [ exportBackup ];
  users.groups.kuma-backup = { };
  users.users.kuma-backup = {
    isSystemUser = true;
    group = "kuma-backup";
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      ''from="100.70.172.120",restrict,command="sudo -n /run/current-system/sw/bin/kuma-backup-export" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICQnr7H5yfpn1/1XL7hrfgREV7Laf+TlzCZ9aBHXw5G/ thoth-kuma-backup''
    ];
  };
  services.openssh.settings.AllowUsers = [ "kuma-backup" ];
  security.sudo.extraRules = [
    {
      users = [ "kuma-backup" ];
      commands = [
        {
          command = ''/run/current-system/sw/bin/kuma-backup-export ""'';
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
