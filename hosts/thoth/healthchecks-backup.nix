{ config, pkgs, ... }:
let
  destination = "/mercury/healthchecks-backup";
  pullBackup = pkgs.writeShellApplication {
    name = "healthchecks-backup-pull";
    runtimeInputs = [ pkgs.coreutils pkgs.openssh pkgs.gnutar pkgs.gzip pkgs.sqlite pkgs.util-linux ];
    text = ''
      umask 077
      # Avoid writing into the root filesystem when the native dataset is absent.
      [[ $(findmnt -n -o SOURCE --mountpoint '${destination}') == mercury/healthchecks-backup ]]
      chmod 0700 '${destination}'
      scratch=$(mktemp -d '${destination}/.incomplete.XXXXXX')
      trap 'rm -rf -- "$scratch"' EXIT
      filename="healthchecks-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
      ssh -T -F /dev/null -p 31225 -i '${config.age.secrets.healthchecks_backup_ssh.path}' \
        -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=30 \
        -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
        -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/etc/ssh/ssh_known_hosts \
        healthchecks-backup@100.125.145.82 > "$scratch/archive.tar.gz"

      mkdir "$scratch/check"
      tar -xzf "$scratch/archive.tar.gz" -C "$scratch/check"
      (cd "$scratch/check" && sha256sum --check SHA256SUMS > /dev/null)
      [[ $(sqlite3 -readonly "$scratch/check/state/healthchecks.sqlite" 'PRAGMA quick_check;') == ok ]]
      [[ -s "$scratch/check/config/SECRET_KEY" ]]
      [[ -s "$scratch/check/config/settings.json" ]]
      mv -n "$scratch/archive.tar.gz" '${destination}/'"$filename"
      ln -sfn "$filename" '${destination}/latest.tar.gz'

      shopt -s nullglob
      archives=('${destination}'/healthchecks-????????T??????Z.tar.gz)
      if (( ''${#archives[@]} > 14 )); then
        for (( i=0; i<''${#archives[@]}-14; i++ )); do
          rm -- "''${archives[i]}"
        done
      fi
      echo "Verified Healthchecks backup saved to ${destination}/$filename"
    '';
  };
in
{
  age.secrets.healthchecks_backup_ssh = {
    file = ../../secrets/healthchecks_backup_ssh.age;
    mode = "0400";
  };
  programs.ssh.knownHosts.heimdall-healthchecks-backup = {
    hostNames = [ "[100.125.145.82]:31225" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuLspM6rRdA76Xmp//5GMEmJBQ6OYj4VA9zpNnLXM7v";
  };
  environment.systemPackages = [ pullBackup ];
  systemd.services.healthchecks-backup = {
    description = "Pull and verify Heimdall Healthchecks backup";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "tailscaled.service" "zfs-mount.service" ];
    unitConfig.RequiresMountsFor = [ destination ];
    onFailure = [ "healthchecks-backup-alert.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pullBackup}/bin/healthchecks-backup-pull";
      TimeoutStartSec = "15min";
      UMask = "0077";
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ destination ];
    };
  };
  systemd.services.healthchecks-backup-alert = {
    description = "Report failed Healthchecks backup";
    serviceConfig.Type = "oneshot";
    script = ''
      /run/current-system/sw/bin/notify alert \
        "Heimdall Healthchecks backup failed" \
        "Thoth could not pull or verify Healthchecks' backup. Check journalctl -u healthchecks-backup."
    '';
  };
  systemd.timers.healthchecks-backup = {
    description = "Nightly Heimdall Healthchecks backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      RandomizedDelaySec = "15min";
      Persistent = true;
    };
  };
}
