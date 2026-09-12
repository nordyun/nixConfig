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
  thoth = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuLI5KeSGBt/+iUlf7LYeeu4PS7n/sfr9iewfLldnw9";
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
    thoth
  ];
in
{
  "tailscale_key.age".publicKeys = users ++ systems;
  "washpw.age".publicKeys = [ wash ] ++ systems;
  "wyattpw.age".publicKeys = users ++ systems;
  "miniIp.age".publicKeys = users ++ systems;
  "syncoidKey.age".publicKeys = [ wash ] ++ [ anubis ] ++ [ thoth ];
  "syncoidConf.age".publicKeys = [ wash ] ++ [ anubis ] ++ [ thoth ];
  "syncoidKH.age".publicKeys = [ wash ] ++ [ anubis ] ++ [ thoth ];
  "pushoverScript.age".publicKeys = [
    wash
    anubis
    neptune
    thoth
  ];
  "pushover_user.age".publicKeys = [
    wash
    anubis
    neptune
    thoth
  ];
  "pushover_token.age".publicKeys = [
    wash
    anubis
    neptune
    thoth
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
    thoth
  ];
  "qobuz_pass.age".publicKeys = [
    wash
    anubis
    thoth
  ];
  "letta-env.age".publicKeys = [
    wash
    anubis
    thoth
  ];
  "letta-mcp-password.age".publicKeys = [
    wash
  ];

  # Google OAuth client secret only (not the downloaded JSON credentials).
  # Add thoth's host key and rekey before migrating Immich there.
  "immich_google_client_secret.age".publicKeys = [ wash anubis thoth ];

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
    thoth
  ];
  "slack_warnings_webhook.age".publicKeys = [
    wash
    anubis
    neptune
    horus
    thoth
  ];
  "monit_collector.age".publicKeys = [
    wash
    anubis
    neptune
    horus
    thoth
  ];
  # Submission login cannot authenticate to the newly configured agent HTTPDs.
  "monit_submission.age".publicKeys = [ wash anubis neptune horus thoth ];
  "monit_control_anubis.age".publicKeys = [ wash anubis ];
  "monit_control_neptune.age".publicKeys = [ wash neptune ];
  "monit_control_horus.age".publicKeys = [ wash horus ];
  "monit_control_thoth.age".publicKeys = [ wash thoth ];
  # Legacy monit_collector retained until the unmanaged Ubuntu agent migrates.
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
    thoth
  ];
  # SNMP read-only community + allowed poller sources (two lines):
  #   rocommunity <random> 127.0.0.1
  #   rocommunity <random> 100.64.0.0/10   (whole tailnet range; community still required)
  "snmp_community.age".publicKeys = [
    wash
    horus
    neptune
    anubis
    thoth
  ];
  # Django SECRET_KEY for healthchecks:  openssl rand -base64 48
  "healthchecks_secret_key.age".publicKeys = [
    wash
    horus
  ];
}
