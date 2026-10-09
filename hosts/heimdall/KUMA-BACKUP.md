# Kuma backups to thoth

Destination: the existing ZFS dataset `mercury/kuma-backup`, mounted at
`/mercury/kuma-backup`. Thoth pulls a backup at 03:30 America/New_York, with up to
15 minutes of random delay. A persistent timer catches a missed run after boot.
The newest 14 successful archives are retained; `latest.tar.gz` points to the
newest. Existing recursive Sanoid configuration covers this dataset on thoth.
Replication of this dataset to Andromeda has not been verified.

Implementation:

- `hosts/heimdall/kuma-backup.nix`: online SQLite backup and state export.
- `hosts/thoth/kuma-backup.nix`: SSH pull, validation, retention, timer, and failure alert.
- `secrets/kuma_backup_ssh.age`: dedicated private key, encrypted only for Wash
  and thoth. Runtime key is root-readable mode 0400.

## How the backup works

Heimdall exports static configuration/assets plus a consistent SQLite `.backup`
of `kuma.db`. SQLite's [online backup API](https://sqlite.org/backup.html) includes
committed WAL contents without stopping Kuma. Live WAL/SHM/journal files are
excluded from the archive so they cannot replace the consistent database copy.
Files outside SQLite are copied while Kuma runs; avoid editing uploaded assets
during a backup if their exact alignment with database changes matters.

Each archive contains `state/`, `SHA256SUMS`, `KUMA_VERSION`, and `BACKUP_TIME`.
Thoth extracts and checks the checksums and SQLite `quick_check` before accepting
the archive. An interrupted/invalid pull leaves no completed archive and never
prunes older backups. The job fails if the expected ZFS dataset is not mounted.
The dataset directory is set to mode 0700 and archives are private to root;
they include account hashes and notification credentials.

The dedicated SSH account/key accepts connections only from thoth's Tailscale
IPv4 `100.70.172.120`, and forces a single export command. It cannot open a shell,
PTY, or forwarding session. The sudo rule permits that exporter without arguments.
Heimdall's SSH host key is pinned. The existing thoth-to-heimdall TCP 31225 grant
already permits the network connection.

Backup failure invokes thoth's existing Slack `#alerts` helper. The job does not
send success notifications. Future Healthchecks integration can detect missed
scheduled runs, including times when thoth cannot send a failure alert.

## Deployment and validation status

Both configurations built successfully from commit `4cf19d6` plus only these
backup changes. Unrelated local shell changes were excluded. The isolated build
checkout on thoth is `/tmp/kuma-backup.IomfmS`.

Heimdall's exporter is deployed. A restricted-key pull through thoth's connection
produced a 37,199-byte archive with one user, one monitor, and one notification.
All file checksums and SQLite's full `integrity_check` passed.

A disposable Kuma 2.5.5 instance restored from that archive started, served its
dashboard with HTTP 200, accepted the restored account, and returned the monitor
with its notification association. The test paused monitors only in its disposable
copy and used systemd `PrivateNetwork=yes` to prevent any external notifications.
Production Kuma remained running.

Thoth activation and the first archive in the dataset are pending. Thoth requires
Wash's sudo password; activate the already-built configuration on thoth:

```sh
sudo nix-env --profile /nix/var/nix/profiles/system --set /nix/store/96nxv7fhwvkz09s4ifrxcwjqq1z90l5l-nixos-system-thoth-26.05.20261006.b253099
sudo /nix/store/96nxv7fhwvkz09s4ifrxcwjqq1z90l5l-nixos-system-thoth-26.05.20261006.b253099/bin/switch-to-configuration switch
sudo systemctl start kuma-backup
```

Then inspect:

```sh
systemctl list-timers kuma-backup.timer
systemctl show kuma-backup.service -p Result -p ExecMainStatus
sudo ls -lh /mercury/kuma-backup
journalctl -u kuma-backup -n 30
```

The oneshot service is normally inactive after a successful run; `Result=success`
and `ExecMainStatus=0` establish the outcome. The timer should be active.

## Restoring production

Use the archive's `KUMA_VERSION` to restore with the matching Kuma version first.
Validate its checksums and SQLite integrity in a temporary directory. Stop Kuma
only when ready to restore, and preserve its current state for rollback.

Restore the archive's `state/` contents into `/var/lib/uptime-kuma/`, replacing the
database and removing old `kuma.db-wal`, `kuma.db-shm`, and `kuma.db-journal` from the
previous database. Restore ownership using the existing state directory as the
reference, so this works even while the transient DynamicUser is stopped:

```sh
sudo chown -R --reference=/var/lib/uptime-kuma/ /var/lib/uptime-kuma/
sudo systemctl start uptime-kuma
```

Use the existing service-created state directory, including its DynamicUser
mapping under `/var/lib/private`; do not recreate it with an old numeric UID from
the archive. Confirm dashboard/login, monitor settings, and notification settings
before resuming normal operations. Restoring older settings can change monitor
targets and stored notification credentials; review those in the restored UI.
