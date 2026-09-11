# Shared `monit` agent: a baseline of system/filesystem checks plus a declarative
# list of systemd services to keep alive, with Slack alerts via `notify`
# (modules/notify.nix, which this expects to be imported alongside).
#
#   myMonit.processes.<unit> = { matching = "..."; pidfile = "..."; restart = true; };
#   myMonit.collector.enable = true;   # report to M/Monit on horus (Phase 1+)
#   myMonit.extraConfig = "...";       # raw monitrc appended verbatim
#
# Collector submission and agent control use separate agenix secrets.
# monit_submission contains only `set mmonit http://monit:PASSWORD@.../collector`.
# monit_control_<host> contains a complete `set httpd` block, allowing localhost
# and Horus (100.86.167.115), with a unique mmonit_<host>:PASSWORD login.
# Each control secret is encrypted only to its host and the administrator.
# Monit registers that host's control credentials with M/Monit automatically.
# Keep both host allow entries AND password authentication: Monit requires both.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myMonit;

  # monit `exec` takes a single bare path (no shell, no args), so bake each
  # notification into its own tiny script.
  mkExec =
    sev: title: body:
    pkgs.writeShellScript "monit-notify-${lib.strings.sanitizeDerivationName "${sev}-${title}"}" ''
      exec /run/current-system/sw/bin/notify ${sev} ${lib.escapeShellArg title} ${lib.escapeShellArg body}
    '';

  systemctl = "${config.systemd.package}/bin/systemctl";

  host = config.networking.hostName;

  processCheck =
    unit: p:
    let
      selector =
        if p.pidfile != null then
          ''with pidfile ${p.pidfile}''
        else
          ''matching "${if p.matching != null then p.matching else unit}"'';
    in
    lib.concatStringsSep "\n" (
      [
        ''check process ${unit} ${selector}''
        ''  start program = "${systemctl} start ${unit}" with timeout 90 seconds''
        ''  stop program  = "${systemctl} stop ${unit}" with timeout 90 seconds''
      ]
      ++ lib.optional p.restart ''  if does not exist for 3 cycles then restart''
      ++ [
        ''  if does not exist for 8 cycles then exec "${mkExec "alert" "${unit} down" "monit could not keep ${unit} running on ${host}"}"''
        ''  if 4 restarts within 8 cycles then exec "${mkExec "alert" "${unit} flapping" "unmonitoring ${unit} on ${host} after repeated restart failures"}"''
        ''  if 4 restarts within 8 cycles then unmonitor''
        ""
      ]
    );
in
{
  options.myMonit = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the shared monit agent.";
    };

    processes = lib.mkOption {
      default = { };
      description = "systemd units for monit to watch, keyed by unit name.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            matching = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "process-table match pattern; defaults to the unit name.";
            };
            pidfile = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "pidfile to check instead of a process match.";
            };
            restart = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "let monit restart the unit before alerting.";
            };
          };
        }
      );
    };

    collector.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Report to M/Monit using separate submission and per-host control secrets.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Raw monitrc appended after the generated checks.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d /var/lib/monit 0700 root root -" ];

    age.secrets = lib.mkIf cfg.collector.enable {
      monit_submission.file = ../secrets/monit_submission.age;
      monit_control.file = ../secrets + "/monit_control_${host}.age";
    };

    # Monit's own source allowlist restricts access even while tailscale0 is trusted.
    networking.firewall.interfaces."tailscale0".allowedTCPPorts =
      lib.mkIf cfg.collector.enable [ 2812 ];

    services.monit.enable = true;
    services.monit.config = ''
      set daemon 30
        with start delay 30
      set log syslog
      set idfile /var/lib/monit/id
      set statefile /var/lib/monit/state
      set eventqueue basedir /var/lib/monit slots 100

      ${
        if cfg.collector.enable then
          ''
            include ${config.age.secrets.monit_submission.path}
            include ${config.age.secrets.monit_control.path}
          ''
        else
          ''
            set httpd port 2812
              use address localhost
              allow localhost
          ''
      }

      check system ${config.networking.hostName}
        if loadavg (5min) per core > 3 for 6 cycles then exec "${mkExec "warn" "load high" "5-min loadavg above 3 per core on ${config.networking.hostName}"}"
        if memory usage > 90% for 6 cycles then exec "${mkExec "warn" "memory over 90%" "sustained high memory usage on ${config.networking.hostName}"}"
        if swap usage > 50% for 6 cycles then exec "${mkExec "warn" "swap over 50%" "sustained swap usage on ${config.networking.hostName}"}"

      check filesystem rootfs with path /
        if space usage > 90% then exec "${mkExec "alert" "rootfs over 90%" "/ is nearly full on ${config.networking.hostName}"}"
        if inode usage > 90% then exec "${mkExec "alert" "rootfs inodes over 90%" "/ is nearly out of inodes on ${config.networking.hostName}"}"

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList processCheck cfg.processes)}

      ${cfg.extraConfig}
    '';
  };
}
