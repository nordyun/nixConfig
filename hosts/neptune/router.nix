{ config, ... }:
{
  boot.kernel.sysctl = {
    # if you use ipv4, this is all you need
    "net.ipv4.conf.all.forwarding" = true;

    # If you want to use it for ipv6
    "net.ipv6.conf.all.forwarding" = true;

    # source: https://github.com/mdlayher/homelab/blob/master/nixos/routnerr-2/configuration.nix#L52
    # By default, not automatically configure any IPv6 addresses.
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 0;

    # On WAN, allow IPv6 autoconfiguration and tempory address use.
    "net.ipv6.conf.wan.accept_ra" = 2;
    "net.ipv6.conf.wan.autoconf" = 1;

    # Better network performance
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # QUIC recommendations testing
    "net.core.rmem_max" = 7500000;
    "net.core.wmem_max" = 7500000;
  };

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ "enp2s0" "agents" ];
      };
      lease-database = {
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
        type = "memfile";
      };
      option-data = [
        {
          name = "domain-name-servers";
          data = "10.1.1.1";
          always-send = true;
        }
        {
          name = "routers";
          data = "10.1.1.1";
        }
        {
          name = "domain-name";
          data = "${config.networking.hostName}.lan";
        }
      ];

      rebind-timer = 2000;
      renew-timer = 1000;
      valid-lifetime = 4000;

      subnet4 = [
        {
          pools = [
            {
              pool = "10.1.1.5 - 10.1.1.250";
            }
          ];
          subnet = "10.1.1.0/24";
          #          reservations = [
          #            {
          #              hw-address = mac-address;
          #              ip-address = ip-address;
          #            }
          #            {
          #              hw-address = mac-address;
          #              ip-address = ip-address;
          #            }
          #          ];
          id = 1;
        }
        {
          id = 20;
          subnet = "10.1.20.0/24";
          interface = "agents";
          pools = [
            {
              pool = "10.1.20.10 - 10.1.20.200";
            }
          ];
          option-data = [
            {
              name = "routers";
              data = "10.1.20.1";
            }
            {
              name = "domain-name-servers";
              data = "10.1.20.1";
              always-send = true;
            }
            {
              name = "domain-name";
              data = "agents.lan";
            }
          ];
        }
      ];
    };
  };
  networking = {
    nat = {
      enable = true;
      internalInterfaces = [ "enp2s0" "agents" ];
      externalInterface = "enp1s0";
    };
    vlans.agents = {
      id = 20;
      interface = "enp2s0";
    };
    interfaces = {
      enp1s0.useDHCP = true;
      enp2s0 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "10.1.1.1";
            prefixLength = 24;
          }
        ];
      };
      agents = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "10.1.20.1";
            prefixLength = 24;
          }
        ];
      };
    };
    firewall.interfaces."enp2s0" = {
      allowedTCPPorts = [
        53
        31225
        # 80
        # 443
      ];
      allowedUDPPorts = [
        53
        31225
      ];
    };
    # Fully-quarantined "agents" VLAN: only DNS + DHCP from neptune itself,
    # no L3 reachability between agents <-> main LAN.
    firewall.interfaces."agents" = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 67 ];
    };
    firewall.extraCommands = ''
      iptables -I FORWARD -i agents -o enp2s0 -j DROP
      iptables -I FORWARD -i enp2s0 -o agents -j DROP
      # allowPing = true (NixOS default) accepts ICMP on every interface;
      # explicitly drop ICMP from agents so the VLAN can't probe neptune itself.
      iptables -I INPUT -i agents -p icmp -j DROP
    '';
    dhcpcd = {
      runHook = ''
        if [[ $reason =~ BOUND ]]; then curl --silent --output /dev/null "$(cat ${config.age.secrets.nextdns_url.path})" && echo "Updated IP on $(date)" >> /home/wash/IPCanary.txt ; fi
      '';
    };
  };
  services.cloudflared = {
    enable = true;
    tunnels = {
      "f97e6bff-6565-4e04-9fba-cef5ddb2cc38" = {
        credentialsFile = "${config.age.secrets.cloudflared-n8n.path}";
        default = "http_status:404";
      };
    };
  };
  age.secrets.cloudflared-n8n.file = ../../secrets/cloudflared-n8n.age;
  age.secrets.nextdns_url.file = ../../secrets/nextdns_url.age;

}
