{ config, pkgs, ... }:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    authKeyFile = config.age.secrets.tailscale_key.path;
    # Neptune is the home exit node. Clear the persisted advertisement too.
    extraSetFlags = [ "--advertise-exit-node=false" ];
  };

  # Optional: ethtool GRO settings for improved performance
  systemd.services.tailscale-gro = {
    description = "Configure GRO settings for Tailscale";
    after = [ "network-online.target" "tailscale.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      # Wait for network to be ready (retry up to 30 seconds)
      sleep 10
      for i in {1..30}; do
        NETDEV="$(${pkgs.iproute2}/bin/ip -o route get 8.8.8.8 2>/dev/null | ${pkgs.coreutils}/bin/cut -f 5 -d " ")"
        if [ -n "$NETDEV" ]; then
          break
        fi
        echo "Waiting for network to be ready... ($i/30)"
        sleep 1
      done

      if [ -z "$NETDEV" ]; then
        echo "Failed to determine network device after 30 seconds"
        exit 1
      fi

      echo "Configuring GRO settings on $NETDEV"
      ${pkgs.ethtool}/bin/ethtool -K "$NETDEV" rx-udp-gro-forwarding on || true
      ${pkgs.ethtool}/bin/ethtool -K "$NETDEV" rx-gro-list off || true
    '';
  };

  environment.systemPackages = with pkgs; [
    tailscale
    iproute2
    ethtool
  ];

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  age.secrets.tailscale_key.file = ../../secrets/tailscale_key.age;
}
