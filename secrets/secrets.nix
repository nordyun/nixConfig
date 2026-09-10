let
  wash = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINpkjlRIlhvQhBM54u+1jbuH3cNesjb+9xyUfTz7/O9";
  wyatt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJvI27JrNE4d90nePxI0jzJrpUA6pecuBONusQpuEfuP";
  users = [
    wash
    wyatt
  ];

  anubis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFE4rG9LOLWZJq38YRZlK7lNK3lL8HYRn61sgp6CrDcJ";
  neptune = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHGaDdqPC3F7hfYYU4b181GxcLkAZyTBAWHJ23hUWiI3";
  zelda = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQ/40iaZdCUOK24lAyPmyt1SJVaLKGQK50FZCm5Mzbt";
  nixmacVM = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL4dWVZcNnAXGKgF0ZlzGCIkD93pODqU05qH7RzhPIWv";
  horus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVkkDUut8az0TvR48sZCqoJVssvsw/Lu5ibSOsm3kQ0";
  # TODO(thoth): after install, add thoth's host key here (from
  # /etc/ssh/ssh_host_ed25519_key.pub on thoth), add `thoth` to `systems`
  # below and to the per-secret lists it needs (tailscale_key, washpw,
  # syncoidKey, syncoidConf, syncoidKH, pushover_user, pushover_token),
  # then run `agenix -r`.
  # thoth = "ssh-ed25519 AAAA... thoth";
  systems = [
    anubis
    neptune
    zelda
    nixmacVM
    horus
  ];
in
{
  "tailscale_key.age".publicKeys = users ++ systems;
  "washpw.age".publicKeys = [ wash ] ++ systems;
  "wyattpw.age".publicKeys = users ++ systems;
  "miniIp.age".publicKeys = users ++ systems;
  "syncoidKey.age".publicKeys = [ wash ] ++ [ anubis ];
  "syncoidConf.age".publicKeys = [ wash ] ++ [ anubis ];
  "syncoidKH.age".publicKeys = [ wash ] ++ [ anubis ];
  "pushoverScript.age".publicKeys = [
    wash
    anubis
    neptune
  ];
  "pushover_user.age".publicKeys = [
    wash
    anubis
    neptune
  ];
  "pushover_token.age".publicKeys = [
    wash
    anubis
    neptune
  ];
  "atuinKey.age".publicKeys = [ wash ];
  "nextdns_url.age".publicKeys = [
    wash
    neptune
  ];
  "dns_url.age".publicKeys = [
    wash
    neptune
  ];
  "cloudflared-n8n.age".publicKeys = [
    wash
    neptune
  ];
  "qobuz_user.age".publicKeys = [
    wash
    anubis
  ];
  "qobuz_pass.age".publicKeys = [
    wash
    anubis
  ];
  "letta-env.age".publicKeys = [
    wash
    anubis
  ];
  "letta-mcp-password.age".publicKeys = [
    wash
  ];

  # --- monitoring (horus + thoth) ---
  # Slack incoming-webhook URLs consumed by modules/notify.nix. `monit_collector`
  # holds the full `set httpd` / `set mmonit` block for agents reporting to the
  # M/Monit collector on horus (modules/monit.nix, collector.enable = true).
  # TODO: add `thoth` to each list once its host key exists, then `agenix -r`.
  "slack_alerts_webhook.age".publicKeys = [
    wash
    anubis
    neptune
    horus
  ];
  "slack_warnings_webhook.age".publicKeys = [
    wash
    anubis
    neptune
    horus
  ];
  "monit_collector.age".publicKeys = [
    wash
    anubis
    neptune
    horus
  ];
  "mmonit_license.age".publicKeys = [
    wash
    horus
  ];
  "nut_upsmon_pw.age".publicKeys = [
    wash
    horus
  ];
  # netclient password for neptune/thoth to monitor horus's upsd (add thoth when installed)
  "nut_remote_pw.age".publicKeys = [
    wash
    horus
    neptune
  ];
  # SNMP read-only community + allowed poller sources (two lines):
  #   rocommunity <random> 127.0.0.1
  #   rocommunity <random> 100.64.0.0/10   (whole tailnet range; community still required)
  "snmp_community.age".publicKeys = [
    wash
    horus
    neptune
    anubis
  ];
  # Django SECRET_KEY for healthchecks:  openssl rand -base64 48
  "healthchecks_secret_key.age".publicKeys = [
    wash
    horus
  ];
}
