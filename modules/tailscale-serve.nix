# Declarative `tailscale serve` mounts: expose local services as valid-HTTPS
# endpoints on this node's MagicDNS name, one per port.
#
#   myTailscaleServe.mounts."8443" = "http://127.0.0.1:8080";
#
# -> https://<node>.<tailnet>.ts.net:8443/  proxies to 127.0.0.1:8080
#
# Needs MagicDNS + "HTTPS Certificates" enabled in the tailnet admin console.
# A oneshot re-applies the whole set on activation (brief blip on rebuilds).
{ config, lib, pkgs, ... }:
let
  cfg = config.myTailscaleServe;
  ts = lib.getExe pkgs.tailscale;
in
{
  options.myTailscaleServe.mounts = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = ''HTTPS port -> local target for `tailscale serve`.'';
  };

  config = lib.mkIf (cfg.mounts != { }) {
    systemd.services.tailscale-serve = {
      description = "Declarative tailscale serve mounts";
      after = [
        "tailscaled.service"
        "tailscaled-autoconnect.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      # wait for the tailnet to be usable, then (re)apply the full set
      script = ''
        for i in $(seq 1 30); do
          ${ts} status --self=true --peers=false >/dev/null 2>&1 && break
          sleep 2
        done

        ${ts} serve reset || true
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            port: target: ''${ts} serve --bg --yes --https ${port} ${lib.escapeShellArg target}''
          ) cfg.mounts
        )}
        ${ts} serve status
      '';

      restartTriggers = [ (builtins.toJSON cfg.mounts) ];
    };
  };
}
