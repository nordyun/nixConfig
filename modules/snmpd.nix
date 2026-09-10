# SNMP agent for LibreNMS to poll. Listens on 0.0.0.0:161 but is only reachable
# on tailscale0 (a trusted interface on every host that imports this) — blocked
# on the LAN. The read-only community + its allowed source live in the
# snmp_community agenix secret (kept out of the world-readable Nix store):
#
#   rocommunity <random-string> <horus tailnet IP>
{ config, lib, ... }:
{
  age.secrets.snmp_community.file = ../secrets/snmp_community.age;

  services.snmpd = {
    enable = true;
    configText = ''
      sysLocation  Homelab
      sysContact   grady@washatka.net
      sysServices  72

      # read-only community + allowed poller source:
      includeFile /run/agenix/snmp_community

      # surface disk / load / memory tables to LibreNMS
      includeAllDisks 10%
    '';
  };

  networking.firewall.interfaces."tailscale0".allowedUDPPorts = [ 161 ];
}
