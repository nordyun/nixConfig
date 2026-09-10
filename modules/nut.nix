# Shared NUT bits for every host with a UPS.
#
# Only the host with the physical UPS (mode netserver/standalone) sends Slack,
# and it routes events through `upssched`: an "on battery" alert only fires if
# the UPS is *still* on battery after myNut.onBattGraceSeconds — so a generator
# cutover (auto-start + transfer switch) doesn't page anyone. Netclients log
# locally and shut down on FSD, but stay silent (horus already alerted).
#
# upsmon runs as root so upssched / the CMDSCRIPT can read the root-only Slack
# webhook secrets.
{ config, lib, pkgs, ... }:
let
  cfg = config.myNut;
  isServer = builtins.elem config.power.ups.mode [
    "standalone"
    "netserver"
  ];
  notify = "/run/current-system/sw/bin/notify";

  # invoked by upssched with a timer/immediate command name as $1
  cmdScript = pkgs.writeShellScript "upssched-cmd" ''
    set -u
    flag=/run/nut/onbatt-notified
    case "''${1:-}" in
      onbatt)
        ${notify} warn "UPS on battery >${toString cfg.onBattGraceSeconds}s" \
          "utility power lost and the generator has not taken over — equipment is on battery"
        touch "$flag" ;;
      online)
        if [ -e "$flag" ]; then
          ${notify} warn "UPS back on line power" "utility or generator power restored"
          rm -f "$flag"
        fi ;;
      lowbatt)  ${notify} alert "UPS LOW BATTERY" "coordinated shutdown imminent"; touch "$flag" ;;
      fsd)      ${notify} alert "UPS forced shutdown" "UPS'd hosts are shutting down now"; touch "$flag" ;;
      commbad)  ${notify} alert "UPS communication lost >60s" "cannot talk to the UPS" ;;
      commok)   ${notify} warn  "UPS communication restored" "" ;;
      replbatt) ${notify} alert "UPS: replace battery" "the last self-test failed" ;;
      nocomm)   ${notify} alert "UPS unreachable" "no UPS reachable" ;;
      *)        ${notify} info  "UPS: ''${1:-unknown}" "" ;;
    esac
  '';

  schedConf = pkgs.writeText "upssched.conf" ''
    CMDSCRIPT ${cmdScript}
    PIPEFN /run/nut/upssched.pipe
    LOCKFN /run/nut/upssched.lock

    AT ONBATT   * START-TIMER onbatt ${toString cfg.onBattGraceSeconds}
    AT ONLINE   * CANCEL-TIMER onbatt
    AT ONLINE   * EXECUTE online
    AT LOWBATT  * EXECUTE lowbatt
    AT FSD      * EXECUTE fsd
    AT COMMBAD  * START-TIMER commbad 60
    AT COMMOK   * CANCEL-TIMER commbad
    AT COMMOK   * EXECUTE commok
    AT REPLBATT * EXECUTE replbatt
    AT NOCOMM   * EXECUTE nocomm
  '';

  mkFlag = ev: [
    ev
    (if isServer then "SYSLOG+WALL+EXEC" else "SYSLOG")
  ];
in
{
  imports = [ ./notify.nix ];

  options.myNut.onBattGraceSeconds = lib.mkOption {
    type = lib.types.int;
    default = 30;
    description = ''
      Seconds the UPS must stay on battery before an "on battery" Slack alert
      fires — rides out the generator's auto-start + transfer-switch cutover.
      Only used on the host with the UPS (netserver/standalone).
    '';
  };

  config = lib.mkIf config.power.ups.enable {
    power.ups.upsmon.user = "root";
    power.ups.upsmon.group = "root";

    power.ups.upsmon.settings.NOTIFYFLAG = map mkFlag [
      "ONLINE"
      "ONBATT"
      "LOWBATT"
      "FSD"
      "SHUTDOWN"
      "COMMBAD"
      "COMMOK"
      "NOCOMM"
      "REPLBATT"
    ];

    power.ups.upsmon.settings.NOTIFYCMD = lib.mkIf isServer "${pkgs.nut}/bin/upssched";
    power.ups.schedulerRules = lib.mkIf isServer "${schedConf}";

    # upssched writes its pipe/lock here
    systemd.tmpfiles.rules = lib.mkIf isServer [ "d /run/nut 0755 root root -" ];
  };
}
