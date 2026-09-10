# Uptime Kuma (black-box checks) + healthchecks (cron dead-man) + homepage
# (the front door). All bound to loopback; tailscale serve fronts them with
# valid HTTPS. See modules/tailscale-serve.nix.
{ config, ... }:
let
  base = "https://horus.taila3fef.ts.net";
in
{
  age.secrets.healthchecks_secret_key = {
    file = ../../secrets/healthchecks_secret_key.age;
    owner = "healthchecks";
  };

  # --- Uptime Kuma :3001 -> serve :10443 ---
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "127.0.0.1";
      PORT = "3001";
    };
  };

  # --- healthchecks :8000 -> serve :11443 ---
  services.healthchecks = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 8000;
    settings = {
      ALLOWED_HOSTS = [ "horus.taila3fef.ts.net" ];
      SECRET_KEY_FILE = config.age.secrets.healthchecks_secret_key.path;
      SITE_ROOT = "${base}:11443";
      SITE_NAME = "horus healthchecks";
      CSRF_TRUSTED_ORIGINS = "${base}:11443";
    };
  };

  # --- homepage :8082 -> serve :443 (root) ---
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "horus.taila3fef.ts.net";
    settings.title = "horus";
    services = [
      {
        "Monitoring" = [
          { "M/Monit" = { href = "${base}:8443"; description = "hosts + processes (white-box)"; }; }
          { "LibreNMS" = { href = "${base}:9443"; description = "SNMP: switch + hosts"; }; }
          { "Uptime Kuma" = { href = "${base}:10443"; description = "black-box checks + status page"; }; }
          { "Healthchecks" = { href = "${base}:11443"; description = "backup / cron dead-man switch"; }; }
        ];
      }
    ];
  };

  myTailscaleServe.mounts = {
    "443" = "http://127.0.0.1:8082";
    "10443" = "http://127.0.0.1:3001";
    "11443" = "http://127.0.0.1:8000";
  };

  # process-match patterns are best guesses; verify with `monit procmatch "<pat>"`
  # on horus after the first deploy and tighten if needed.
  myMonit.processes = {
    uptime-kuma.matching = "uptime-kuma";
    homepage-dashboard.matching = "next-server";
    healthchecks = {
      matching = "hc.wsgi";
      restart = false;
    };
  };
}
