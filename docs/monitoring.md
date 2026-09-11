# Homelab monitoring — `horus`

`horus` (2012 Mac mini, 16 GB, headless, NixOS) is the always-on observability /
infra box. It is deliberately **not** one of the machines it watches, so an
outage of any other host doesn't blind you.

Full build history and remaining work: `~/.claude/plans/alright-this-is-a-inherited-adleman.md`

---

## What runs where

| Layer | Tool | Runs on | Reach it at |
|---|---|---|---|
| White-box (per-host processes, load, disk) | **M/Monit** collector + `monit` agents | collector on horus; agents on horus, neptune, anubis (thoth later) | `https://horus.taila3fef.ts.net:8443/` |
| Network / SNMP (switch + hosts) | **LibreNMS** + `snmpd` | LibreNMS on horus; `snmpd` on horus, neptune, anubis | `https://horus.taila3fef.ts.net:9443/` |
| Black-box (is it reachable / cert expiry) | **Uptime Kuma** | horus | `https://horus.taila3fef.ts.net:10443/` |
| Dead-man's switch (cron / backups) | **healthchecks** | horus | `https://horus.taila3fef.ts.net:11443/` |
| Front door | **homepage-dashboard** | horus | `https://horus.taila3fef.ts.net/` |
| UPS | **NUT** (CyberPower CP1500PFCRM2U) | server on horus; netclients neptune + thoth | — |
| Notifications | `notify` → Slack | all agent hosts | `#alerts`, `#warnings` |

Everything is **tailnet-only**. The dashboards are bound to loopback and fronted
by `tailscale serve` with valid HTTPS on `horus.taila3fef.ts.net`. MagicDNS +
"HTTPS Certificates" must stay enabled in the tailnet admin console.

MagicDNS suffix: `taila3fef.ts.net` · horus tailnet IP: `100.86.167.115`

---

## Nix layout

**Shared modules** (`modules/`):

| File | Provides |
|---|---|
| `notify.nix` | `notify <alert\|warn\|info> <title> <msg>` command → Slack; declares `slack_{alerts,warnings}_webhook` secrets. Degrades silently if a webhook is missing. |
| `monit.nix` | `services.monit` + option `myMonit.processes.<unit> = { matching; pidfile; restart; }`, `myMonit.collector.enable`, `myMonit.extraConfig`. Baseline `check system` + `check filesystem /`. Collector mode uses `monit_submission` and per-host `monit_control_<host>` secrets. Port 2812 requires password authentication and a localhost/Horus source address. |
| `snmpd.nix` | `services.snmpd`, static config + `includeFile /run/agenix/snmp_community`, `:161/udp` on `tailscale0`. |
| `nut.nix` | Shared NUT: routes UPS events → `notify` (server only), runs `upsmon` as root. Server uses `upssched` with an `myNut.onBattGraceSeconds` (default 30) timer so a generator cutover doesn't page. |
| `tailscale-serve.nix` | `myTailscaleServe.mounts."<port>" = "http://127.0.0.1:<n>"` → oneshot `tailscale-serve.service` runs `tailscale serve reset` then `tailscale serve --bg --yes --https <port> <target>` per mount. No `services.tailscale.serve` exists in nixpkgs 26.05. |

**Package** (`pkgs/mmonit/default.nix`): M/Monit 4.3.4, `autoPatchelfHook` over the
vendor tarball. `mmonit -i` = foreground; `-c` = alternate `server.xml`. The
binary chdir()s to its install root, so `hosts/horus/mmonit.nix` seeds a writable
copy in `/var/lib/mmonit` (refreshes `bin/lib/docroot` each start, keeps
`db/conf/logs`).

**Host files**:

| File | Contents |
|---|---|
| `hosts/horus/{default,hardware-configuration,tailscale}.nix` | host scaffold |
| `hosts/horus/monit.nix` | `collector.enable = true`; watches mmonit / mysql (`bin/(mysqld\|mariadbd)`) / phpfpm-librenms / nginx / snmpd / upsd / upsmon / upsdrv / uptime-kuma / next-server / hc.wsgi / tailscaled |
| `hosts/horus/mmonit.nix` | the collector service. `server.xml` gets a 2nd connector on `127.0.0.1:8081` with `proxyScheme="https" proxyName="horus.taila3fef.ts.net" proxyPort="8443"` so the GUI works behind serve; stock `:8080` stays for agents. License installed from `mmonit_license` secret. |
| `hosts/horus/nut.nix` | `power.ups` netserver, `usbhid-ups` on `port = "auto"`, `upsd.listen 0.0.0.0` (tailnet-only via trusted iface) |
| `hosts/horus/librenms.nix` | `services.librenms`, local MariaDB over unix socket (no DB password), nginx on `127.0.0.1:80`. An `ExecStartPost` on `librenms-setup` rewrites the module's hardcoded `APP_URL` to `https://horus.taila3fef.ts.net:9443/`. |
| `hosts/horus/observability.nix` | uptime-kuma (`:3001`), healthchecks (`:8000`, `SECRET_KEY_FILE`, `SITE_ROOT`/`CSRF_TRUSTED_ORIGINS` = the served URL), homepage-dashboard (`:8082`), and the serve mounts for `443`/`10443`/`11443` |
| `hosts/{neptune,anubis}/monit.nix` | `collector.enable = true` + host-specific process checks |
| `hosts/neptune/nut.nix` | `mode = "netclient"` → `cyberpower@100.86.167.115` |
| `hosts/thoth/nut.nix` | same as neptune — **not imported yet** (see "Pending") |

`tailscale_key` and `washpw` cover `horus` via the shared `systems` list in
`secrets/secrets.nix`.

---

## Ports on horus

| Port | Bind | Purpose |
|---|---|---|
| 8080 | `*` | M/Monit — agent collector endpoint (agents POST here directly), open on `tailscale0` |
| 8081 | `127.0.0.1` | M/Monit — proxy-aware GUI connector → served on `:8443` |
| 80 | `127.0.0.1` | LibreNMS nginx → served on `:9443` |
| 3001 / 8000 / 8082 | `127.0.0.1` | Uptime Kuma / healthchecks / homepage → served on `:10443` / `:11443` / `:443` |
| 2812 | `0.0.0.0` | `monit` agent httpd (M/Monit polls it for actions), open on `tailscale0` |
| 3493 | `0.0.0.0` | NUT `upsd`, open on `tailscale0` |
| 161/udp | `0.0.0.0` | `snmpd`, open on `tailscale0` |

The LAN interface has none of these open — `trustedInterfaces = ["tailscale0"]`
allows everything on the tailnet and the firewall default-drops the rest.

---

## Secrets (`secrets/secrets.nix` + `agenix -e`)

| Secret | Recipients | Contents |
|---|---|---|
| `slack_alerts_webhook` / `slack_warnings_webhook` | wash, horus, anubis, neptune | one Slack incoming-webhook URL each |
| `monit_submission` | wash, horus, anubis, neptune | Only the existing `set mmonit` directive; submission login preserved. The current encrypted URL uses `horus.taila3fef.ts.net`. |
| `monit_control_<host>` | wash and the named host only | Complete `set httpd` block, localhost/Horus allowlist, unique `mmonit_<host>` password. |
| `monit_collector` | wash, horus, anubis, neptune | Legacy combined secret, retained temporarily for the unmanaged Ubuntu migration; no longer referenced by the NixOS module. |
| `mmonit_license` | wash, horus | the M/Monit `license.xml` (grab from `/var/lib/mmonit/conf/license.xml`) |
| `nut_upsmon_pw` | wash, horus | random alnum — horus-local upsd `upsmon` user |
| `nut_remote_pw` | wash, horus, neptune | random alnum — netclient `upsmon-remote` user (add thoth later) |
| `snmp_community` | wash, horus, neptune, anubis | two lines: `rocommunity <rand> 127.0.0.1` and `rocommunity <rand> 100.64.0.0/10` |
| `healthchecks_secret_key` | wash, horus | Django `SECRET_KEY` (`openssl rand -base64 48`); secret is `owner = "healthchecks"` |

After editing any: `agenix -r`, commit, push, redeploy the affected hosts.

---

## Notification flow

- **monit** checks `exec` a generated script → `notify` → Slack. `alert` →
  `#alerts` (hard down / failed), `warn`/`info` → `#warnings`.
- **M/Monit** central alerting is configured in its GUI (Admin → Alerts), not in
  Nix — currently unused; per-host `monit exec` covers it.
- **NUT**: only the server (horus) notifies. `ONBATT` starts a 30 s `upssched`
  timer; `ONLINE` cancels it → generator cutover is silent. Sustained battery →
  one `#warnings`. `LOWBATT`/`FSD`/`COMMBAD`/`REPLBATT` → `#alerts`, immediate.
  Netclients log locally only.
- **LibreNMS**: Slack transport added in its GUI (Alerts → Transports).
- **Uptime Kuma**: Slack notification added per-monitor in its GUI.
- **healthchecks**: Slack integration added per-project in its GUI. (Email is not
  configured — the `EMAIL_HOST` warning on `createsuperuser` is expected.)

The non-NixOS **Ubuntu server** on the tailnet runs stock `apt install monit`
with `/etc/monit/conf.d/mmonit.conf` and reports
to the same M/Monit; its alerting goes through M/Monit's central config. Its
unique control password and localhost/Horus source allowlist were deployed as
part of audit finding 4.
See [credential migration and deployment verification](monit-credential-migration.md);
the user confirmed full deployment, including Ubuntu, on 2026-09-11.

---

## Common operations

### Deploy
```bash
# from ~/nixConfig on the Mac
git add -A && git commit -m "…" && git push
# on the target host
git pull && sudo nixos-rebuild switch --flake .#<host>
```
The Mac is aarch64-darwin with no builders — deploy on-box, or
`--build-host root@<host> --target-host root@<host>` for a fresh box on port 22.

### Add a monit agent to a new NixOS host
```nix
# hosts/<host>/monit.nix
imports = [ ../../modules/notify.nix ../../modules/monit.nix ];
myMonit.collector.enable = true;
myMonit.processes = { some-unit.matching = "some-proc"; };
```
Add the host to `slack_*` + `monit_submission` recipients, `agenix -r`.
Create `monit_control_<host>.age` with a unique password and the localhost/Horus
allowlist, encrypted only to wash and the new host; declare its recipients in
`secrets/secrets.nix` before enabling collector mode.
**Verify process patterns** after deploy — NixOS process names surprise you
(`mysqld` not `mariadbd`, `next-server` not `homepage`): `sudo monit procmatch "<pat>"`.

### Add a device to LibreNMS
```bash
C=$(sudo awk '{print $2; exit}' /run/agenix/snmp_community)   # on horus
sudo lnms device:add <fqdn-or-ip> --v2c -c "$C"
```
- NixOS hosts: add by **MagicDNS FQDN** (`neptune.taila3fef.ts.net`) — re-resolved every poll.
- The switch: add by its **LAN IP** (not on tailscale); enable SNMP v2c in its web UI first, community = `$C`, source-restrict to horus's LAN IP.

### Add a NUT netclient (e.g. thoth once installed)
1. `secrets/secrets.nix`: add the host to `nut_remote_pw` recipients, `agenix -r`.
2. Import `./nut.nix` in the host's `default.nix`.
3. Add `upsmon.matching = "upsmon"` to its monit checks.

### UPS test
```bash
upsc cyberpower@localhost            # on horus
upsc cyberpower@100.86.167.115       # from a netclient
```
Pull mains < 30 s → nothing (generator sim). > 30 s → one `#warnings` from horus.
**Do not** trigger a real `LOWBATT`/`fsd` test — it shuts down horus + neptune + thoth.

### M/Monit re-arm an unmonitored check
```bash
sudo monit monitor <name>
```

---

## Gotchas hit during the build (so you don't rediscover them)

- **monit `set mmonit` not `set monit`**; `allow read-only localhost` is invalid
  (use `allow localhost`); collector password must be alphanumeric.
- **neptune has no MagicDNS** (local unbound owns `/etc/resolv.conf`). Fixed with
  an unbound forward-zone `taila3fef.ts.net. → 100.100.100.100`.
  NUT uses the raw `100.86.167.115`; the current Monit submission URL uses
  `horus.taila3fef.ts.net` and depends on that DNS forwarding.
- **NixOS process names**: `mysqld` (not `mariadbd`), `next-server` (not
  `homepage`), gunicorn matched via `hc.wsgi`.
- **`logrotate-checkconf` fails on the first nginx deploy** (log-dir race) — a
  second `nixos-rebuild switch` clears it.
- **M/Monit trial license auto-fetch fails** without `SSL_CERT_FILE` /
  `SSL_CERT_DIR` = `pkgs.cacert` in the unit; it then logs a manual download URL.
- **M/Monit behind serve**: needs the `proxyScheme`/`proxyName`/`proxyPort`
  connector or absolute URLs (redirects, alert links) come out as `http://…:8080`.
- **healthchecks `SECRET_KEY_FILE`** must be `owner = "healthchecks"` or gunicorn
  crash-loops.
- **agenix secrets** used by a service that isn't root need `owner =` set.
- `tailscale serve` re-applies on every rebuild (`serve reset` + re-add) — a
  ~1 s blip on the dashboards during a switch.

---

## Pending

- **Phase 5 — backup reporting**: `OnFailure=` + healthcheck pings on thoth's
  existing sanoid / syncoid / rcloneOnedrive units. Blocked on thoth being
  installed.
- **thoth**, once installed: add its host key to `secrets/secrets.nix`; create
  `hosts/thoth/monit.nix` (collector agent); import `hosts/thoth/nut.nix` +
  add thoth to `nut_remote_pw`.
- **M/Monit license**: 30-day trial — buy before it expires (~early Oct 2026),
  then update `mmonit_license.age`.
- **LibreNMS**: `APP_URL` is rewritten to the served HTTPS URL; if any UI links
  still come out `http://`, LibreNMS may need `APP_TRUSTED_PROXIES` tuning.
- Optional: fold NUT UPS data into LibreNMS via an `snmpd` `extend` + the
  LibreNMS "nut" application.
