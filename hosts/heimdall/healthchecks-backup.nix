{ config, pkgs, ... }:
let
  cfg = config.services.healthchecks;
  settingsSnapshot = pkgs.writeText "healthchecks-backup-settings.json" (builtins.toJSON cfg.settings);
  exportBackup = pkgs.writeShellApplication {
    name = "healthchecks-backup-export";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.rsync pkgs.sqlite pkgs.gnutar pkgs.gzip pkgs.util-linux ];
    text = ''
      if (( $# != 0 )); then
        echo "healthchecks-backup-export takes no arguments" >&2
        exit 1
      fi
      umask 077
      exec 9>/run/healthchecks-backup-export.lock
      flock -w 60 9
      scratch=$(mktemp -d /run/healthchecks-backup.XXXXXX)
      trap 'rm -rf -- "$scratch"' EXIT
      mkdir "$scratch/state" "$scratch/config"

      # Static assets are regenerated from the package. Preserve other local
      # state alongside an online SQLite snapshot, excluding its live journals.
      rsync -a --exclude='/static' --exclude='/healthchecks.sqlite' \
        --exclude='/healthchecks.sqlite-wal' --exclude='/healthchecks.sqlite-shm' \
        --exclude='/healthchecks.sqlite-journal' \
        '${cfg.dataDir}/' "$scratch/state/"
      sqlite3 -readonly '${cfg.dataDir}/healthchecks.sqlite' \
        '.timeout 60000' ".backup '$scratch/state/healthchecks.sqlite'"
      [[ $(sqlite3 -readonly "$scratch/state/healthchecks.sqlite" 'PRAGMA quick_check;') == ok ]]
      install -m 0600 '${config.age.secrets.healthchecks_secret_key.path}' "$scratch/config/SECRET_KEY"
      install -m 0600 '${settingsSnapshot}' "$scratch/config/settings.json"
      printf '%s\n' '${cfg.package.version}' > "$scratch/config/HEALTHCHECKS_VERSION"
      readlink -f /run/current-system > "$scratch/config/SYSTEM_PATH"
      date -u +%FT%TZ > "$scratch/config/BACKUP_TIME"
      cd "$scratch"
      find state config -type f -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
      tar --numeric-owner -czf - state config SHA256SUMS
    '';
  };
in
{
  environment.systemPackages = [ exportBackup ];
  users.groups.healthchecks-backup = { };
  users.users.healthchecks-backup = {
    isSystemUser = true;
    group = "healthchecks-backup";
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      ''from="100.70.172.120",restrict,command="sudo -n /run/current-system/sw/bin/healthchecks-backup-export" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII/S/cNGYu1UD1uIq35NuHSNf9uktM+s3wTib1dxim3t thoth-healthchecks-backup''
    ];
  };
  services.openssh.settings.AllowUsers = [ "healthchecks-backup" ];
  security.sudo.extraRules = [
    {
      users = [ "healthchecks-backup" ];
      commands = [
        {
          command = ''/run/current-system/sw/bin/healthchecks-backup-export ""'';
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
