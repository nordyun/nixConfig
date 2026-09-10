# LibreNMS — SNMP monitoring for the TP-Link T1600G-28PS switch + the NixOS
# hosts (via modules/snmpd.nix). Local MariaDB over the unix socket (no DB
# password to manage). nginx binds loopback; tailscale serve fronts it with
# valid HTTPS at  https://horus.taila3fef.ts.net:9443/  (modules/tailscale-serve.nix).
#
# The librenms module hardcodes APP_URL to http://<hostname>/ with no port, so
# an ExecStartPost rewrites it to the real served URL (+ trusts the loopback
# proxy) and clears the config cache.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  servedUrl = "https://horus.taila3fef.ts.net:9443";
  fixEnv = pkgs.writeShellScript "librenms-served-url" ''
    env=/var/lib/librenms/.env
    ${lib.getExe pkgs.gnused} -i 's|^APP_URL=.*|APP_URL=${servedUrl}/|' "$env"
    ${lib.getExe pkgs.gnugrep} -q '^APP_TRUSTED_PROXIES=' "$env" \
      || echo 'APP_TRUSTED_PROXIES=127.0.0.1' >> "$env"
    ${config.services.librenms.finalPackage}/artisan config:clear >/dev/null 2>&1 || true
  '';
in
{
  services.librenms = {
    enable = true;
    hostname = "horus.taila3fef.ts.net";
    pollerThreads = 8;

    database = {
      createLocally = true;
      socket = "/run/mysqld/mysqld.sock";
    };

    nginx = {
      default = true;
      listen = [
        {
          addr = "127.0.0.1";
          port = 80;
        }
      ];
    };
  };

  systemd.services.librenms-setup.serviceConfig.ExecStartPost = fixEnv;

  myTailscaleServe.mounts."9443" = "http://127.0.0.1:80";
}
