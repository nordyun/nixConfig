# Shared NUT bits for every host with a UPS (server or netclient):
#   - route UPS events to Slack via `notify`
#   - run upsmon as root so its NOTIFYCMD exec can read the root-only webhook secrets
# Host configs (hosts/<host>/nut.nix) set the mode / ups / monitor specifics.
{ config, lib, pkgs, ... }:
let
  notify = "/run/current-system/sw/bin/notify";

  # upsmon invokes NOTIFYCMD as: <cmd> "<message>"  with $NOTIFYTYPE set.
  onEvent = pkgs.writeShellScript "nut-notify" ''
    set -u
    msg="''${1:-}"
    case "''${NOTIFYTYPE:-}" in
      ONBATT)   ${notify} warn  "UPS on battery"             "$msg" ;;
      ONLINE)   ${notify} warn  "UPS back on line power"     "$msg" ;;
      LOWBATT)  ${notify} alert "UPS LOW BATTERY"            "$msg" ;;
      FSD)      ${notify} alert "UPS forced shutdown"        "$msg" ;;
      SHUTDOWN) ${notify} alert "UPS shutdown initiated"     "$msg" ;;
      COMMBAD)  ${notify} alert "UPS communication lost"     "$msg" ;;
      NOCOMM)   ${notify} alert "UPS unreachable"            "$msg" ;;
      COMMOK)   ${notify} warn  "UPS communication restored" "$msg" ;;
      REPLBATT) ${notify} alert "UPS: replace battery"       "$msg" ;;
      *)        ${notify} info  "UPS: ''${NOTIFYTYPE:-unknown}" "$msg" ;;
    esac
  '';
in
{
  imports = [ ./notify.nix ];

  config = lib.mkIf config.power.ups.enable {
    power.ups.upsmon.user = "root";
    power.ups.upsmon.group = "root";
    power.ups.upsmon.settings = {
      NOTIFYCMD = "${onEvent}";
      NOTIFYFLAG = [
        [ "ONLINE" "SYSLOG+WALL+EXEC" ]
        [ "ONBATT" "SYSLOG+WALL+EXEC" ]
        [ "LOWBATT" "SYSLOG+WALL+EXEC" ]
        [ "FSD" "SYSLOG+WALL+EXEC" ]
        [ "SHUTDOWN" "SYSLOG+WALL+EXEC" ]
        [ "COMMBAD" "SYSLOG+EXEC" ]
        [ "COMMOK" "SYSLOG+EXEC" ]
        [ "NOCOMM" "SYSLOG+EXEC" ]
        [ "REPLBATT" "SYSLOG+WALL+EXEC" ]
      ];
    };
  };
}
