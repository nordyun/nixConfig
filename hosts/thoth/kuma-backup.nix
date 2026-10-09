{ config, pkgs, ... }:
let
  destination = "/mercury/kuma-backup";
  pullBackup = pkgs.writeShellApplication {
    name = "kuma-backup-pull";
    runtimeInputs = [ pkgs.coreutils pkgs.openssh pkgs.gnutar pkgs.gzip pkgs.sqlite pkgs.util-linux pkgs.curl ];
    text = ''
      umask 077
      # Monitoring is best effort: an unavailable endpoint must not stop a backup.
      # Feed the bearer URL through stdin rather than exposing it in argv/logs.
      ping_healthchecks() {
        local suffix="$1" url
        if ! IFS= read -r url < '${config.age.secrets.kuma_backup_healthchecks.path}'; then
          echo "Healthchecks ping URL unavailable" >&2
          return 0
        fi
        if ! printf 'url = "%s%s"\n' "$url" "$suffix" |
          curl --config - --silent --fail --output /dev/null \
            --connect-timeout 5 --max-time 10; then
          echo "Healthchecks check-in could not be delivered" >&2
        fi
      }
      scratch=""
      finish() {
        local result=$?
        trap - EXIT
        if (( result != 0 )); then
          ping_healthchecks /fail
        fi
        if [[ -n "$scratch" ]]; then
          rm -rf -- "$scratch"
        fi
        exit "$result"
      }
      trap finish EXIT
      ping_healthchecks /start
      # Fail if the native ZFS dataset is unavailable, rather than writing to /.
      [[ $(findmnt -n -o SOURCE --mountpoint '${destination}') == mercury/kuma-backup ]]
      chmod 0700 '${destination}'
      scratch=$(mktemp -d '${destination}/.incomplete.XXXXXX')
      filename="kuma-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
      ssh -F /dev/null -p 31225 -i '${config.age.secrets.kuma_backup_ssh.path}' \
        -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=30 \
        -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
        -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/etc/ssh/ssh_known_hosts \
        kuma-backup@100.125.145.82 > "$scratch/archive.tar.gz"

      mkdir "$scratch/check"
      tar -xzf "$scratch/archive.tar.gz" -C "$scratch/check"
      (cd "$scratch/check" && sha256sum --check SHA256SUMS > /dev/null)
      [[ $(sqlite3 -readonly "$scratch/check/state/kuma.db" 'PRAGMA quick_check;') == ok ]]
      mv -n "$scratch/archive.tar.gz" '${destination}/'"$filename"
      ln -sfn "$filename" '${destination}/latest.tar.gz'

      # Retain the newest 14 successful pulls. Incomplete transfers never prune.
      shopt -s nullglob
      archives=('${destination}'/kuma-????????T??????Z.tar.gz)
      if (( ''${#archives[@]} > 14 )); then
        for (( i=0; i<''${#archives[@]}-14; i++ )); do
          rm -- "''${archives[i]}"
        done
      fi
      echo "Verified Kuma backup saved to ${destination}/$filename"
      ping_healthchecks ""
    '';
  };
in
{
  age.secrets.kuma_backup_ssh = {
    file = ../../secrets/kuma_backup_ssh.age;
    mode = "0400";
  };
  age.secrets.kuma_backup_healthchecks = {
    file = ../../secrets/kuma_backup_healthchecks.age;
    mode = "0400";
  };
  programs.ssh.knownHosts.heimdall-kuma-backup = {
    hostNames = [ "[100.125.145.82]:31225" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuLspM6rRdA76Xmp//5GMEmJBQ6OYj4VA9zpNnLXM7v";
  };
  environment.systemPackages = [ pullBackup ];
  systemd.services.kuma-backup = {
    description = "Pull and verify Heimdall Kuma backup";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "tailscaled.service" "zfs-mount.service" ];
    unitConfig.RequiresMountsFor = [ destination ];
    onFailure = [ "kuma-backup-alert.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pullBackup}/bin/kuma-backup-pull";
      TimeoutStartSec = "15min";
      UMask = "0077";
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ destination ];
    };
  };
  systemd.services.kuma-backup-alert = {
    description = "Report failed Kuma backup";
    serviceConfig.Type = "oneshot";
    script = ''
      /run/current-system/sw/bin/notify alert \
        "Heimdall Kuma backup failed" \
        "Thoth could not pull or verify Kuma's backup. Check journalctl -u kuma-backup."
    '';
  };
  systemd.timers.kuma-backup = {
    description = "Nightly Heimdall Kuma backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:30:00";
      RandomizedDelaySec = "15min";
      Persistent = true;
    };
  };
}
