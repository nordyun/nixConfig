# Observed Debian lease: 40.160.91.53/32, gateway 40.160.91.1.
# DHCP supplies IPv4, gateway routes, and DNS; IPv6 was configured statically.
{ ... }:
{
  networking.useDHCP = false;
  networking.useNetworkd = true;
  services.resolved.enable = true;

  systemd.network.networks."10-wan" = {
    # Remain independent of predictable interface naming differences.
    matchConfig.MACAddress = "fa:16:3e:4c:71:75";
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = false;
    };
    dhcpV4Config = {
      UseDNS = true;
      UseRoutes = true;
      RouteMetric = 100;
    };
    address = [ "2604:2dc0:101:200::4588/128" ];
    routes = [
      { Destination = "2604:2dc0:101:200::/64"; Scope = "link"; }
      {
        Destination = "::/0";
        Gateway = "2604:2dc0:101:200::1";
        GatewayOnLink = true;
      }
    ];
    linkConfig.RequiredForOnline = "routable";
  };
}
