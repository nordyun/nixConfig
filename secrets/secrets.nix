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
  systems = [
    anubis
    neptune
    zelda
    nixmacVM
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
}
