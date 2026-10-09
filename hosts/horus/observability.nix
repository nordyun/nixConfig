# Homepage stays local; Kuma and Healthchecks run offsite on heimdall.
# Tailscale Serve fronts the loopback backend with HTTPS.
{ ... }:
let
  base = "https://horus.taila3fef.ts.net";
in
{
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
          { "Uptime Kuma" = { href = "https://heimdall.taila3fef.ts.net:10443"; description = "offsite availability checks"; }; }
          { "Healthchecks" = { href = "https://heimdall.taila3fef.ts.net:11443"; description = "offsite backup / cron check-ins"; }; }
        ];
      }
    ];
  };

  myTailscaleServe.mounts = {
    "443" = "http://127.0.0.1:8082";
  };

  # process-match patterns are best guesses; verify with `monit procmatch "<pat>"`
  # on horus after the first deploy and tighten if needed.
  myMonit.processes = {
    homepage-dashboard.matching = "next-server";
  };
}
