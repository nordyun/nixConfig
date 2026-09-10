# NUT — monitors the CyberPower CP1500PFCRM2U over USB (usbhid-ups).
#
# mode = "standalone": upsd + upsmon + driver all run locally, and horus shuts
# *itself* down cleanly on low battery. UPS events -> notify -> Slack.
#
# To also protect other hosts (coordinated shutdown when the UPS is low):
#   - here: mode = "netserver", add a tailnet address to upsd.listen, open
#     :3493 on tailscale0
#   - on each downstream host: power.ups.mode = "netclient" with a
#     power.ups.upsmon.monitor.<name> pointing at horus:3493 as a "secondary"
#     user (add that user to power.ups.users here).
{ config, pkgs, ... }:
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
  age.secrets.nut_upsmon_pw.file = ../../secrets/nut_upsmon_pw.age;

  power.ups = {
    enable = true;
    mode = "standalone";

    ups.cyberpower = {
      driver = "usbhid-ups";
      port = "auto";
      description = "CyberPower CP1500PFCRM2U";
    };

    users.upsmon = {
      passwordFile = config.age.secrets.nut_upsmon_pw.path;
      upsmon = "primary";
    };

    upsmon.monitor.cyberpower = {
      user = "upsmon";
      type = "primary";
      # passwordFile defaults to users.upsmon.passwordFile
    };

    # NOTIFYCMD runs as the upsmon user and must read the root-owned Slack
    # webhook secrets, so run upsmon as root (upsd / upsdrv already do).
    upsmon.user = "root";
    upsmon.group = "root";

    upsmon.settings = {
      NOTIFYCMD = "${onEvent}";
      NOTIFYFLAG = [
        [ "ONLINE"   "SYSLOG+WALL+EXEC" ]
        [ "ONBATT"   "SYSLOG+WALL+EXEC" ]
        [ "LOWBATT"  "SYSLOG+WALL+EXEC" ]
        [ "FSD"      "SYSLOG+WALL+EXEC" ]
        [ "SHUTDOWN" "SYSLOG+WALL+EXEC" ]
        [ "COMMBAD"  "SYSLOG+EXEC" ]
        [ "COMMOK"   "SYSLOG+EXEC" ]
        [ "NOCOMM"   "SYSLOG+EXEC" ]
        [ "REPLBATT" "SYSLOG+WALL+EXEC" ]
      ];
    };
  };
}
