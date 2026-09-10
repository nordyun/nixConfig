# LibreNMS — SNMP monitoring for the TP-Link T1600G-28PS switch + the NixOS
# hosts (via modules/snmpd.nix). Local MariaDB over the unix socket (no DB
# password to manage). nginx serves the UI on :80, tailnet-only via horus's
# trustedInterfaces = ["tailscale0"].
#
# Reach it at  http://horus.taila3fef.ts.net/  over the tailnet.
# (Phase 4 puts it behind tailscale serve for HTTPS.)
#
# First deploy: `systemctl status librenms-setup` runs migrations + generates
# .env. Then create the admin user and add devices — see the deploy notes.
{ ... }:
{
  services.librenms = {
    enable = true;
    hostname = "horus.taila3fef.ts.net";
    pollerThreads = 8;

    database = {
      createLocally = true;
      socket = "/run/mysqld/mysqld.sock";
    };

    # respond regardless of Host header (name or tailnet IP)
    nginx.default = true;
  };
}
