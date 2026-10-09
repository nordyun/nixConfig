{ inputs, ... }:
{
  imports = [
    inputs.agenix.nixosModules.default
    ../../modules/tailscale-serve.nix
  ];

  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "127.0.0.1";
      PORT = "3001";
    };
  };

  myTailscaleServe.mounts."10443" = "http://127.0.0.1:3001";

  # Used during initial Slack notification setup. Kuma stores its configured
  # notification in its own database, which must be backed up separately.
  age.secrets.slack_alerts_webhook = {
    file = ../../secrets/slack_alerts_webhook.age;
    mode = "0400";
  };

  services.monit.config = ''
    check host kuma with address 127.0.0.1
      if failed port 3001 protocol http for 3 cycles then alert
  '';
}
