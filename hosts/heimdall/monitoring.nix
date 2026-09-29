# Local checks only. External notifications and collection come after enrollment.
{ ... }:
{
  systemd.tmpfiles.rules = [ "d /var/lib/monit 0700 root root -" ];
  services.monit = {
    enable = true;
    config = ''
      set daemon 60 with start delay 120
      set log syslog
      set idfile /var/lib/monit/id
      set statefile /var/lib/monit/state
      set httpd port 2812
        use address localhost
        allow localhost

      check system heimdall
        if memory usage > 85% for 5 cycles then alert
        if loadavg (5min) per core > 3 for 5 cycles then alert

      check filesystem rootfs with path /
        if space usage > 85% then alert
        if inode usage > 90% then alert

      check host ssh with address 127.0.0.1
        if failed port 31225 protocol ssh for 3 cycles then alert
    '';
  };
}
