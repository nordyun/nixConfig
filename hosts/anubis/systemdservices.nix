{ pkgs, ... }:
{
  # systemd.user.services.wayvnc = {
  #   enable = true;
  #   after = [ "graphical-session.target" ];
  #   partOf = [ "graphical-session.target" ];
  #   wantedBy = [ "graphical-session.target" ];
  #   description = "Automatically start Wayvnc";
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = ''${pkgs.wayvnc}/bin/wayvnc 0.0.0.0 -o HDMI-A-1'';
  #     Restart = "on-failure";
  #     RestartSec = "5s";
  #   };
  # };
  systemd.timers.rsync-flights = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 00/6:00:00"; # every 6 hours
      Persistent = true;
      Unit = "rsync-flights.service";
    };
  };
  systemd.services.rsync-flights = {
    enable = true;
    description = "Rsync Obsidian flights to n8n-files";
    serviceConfig = {
      Type = "oneshot";
      User = "wash";
      Group = "users";
      ExecStart = "${pkgs.rsync}/bin/rsync -a /mercury/alpha/Obsidian/N_Prime/Library/Media/Flights/ /home/wash/n8n-files/trips/";
    };
  };
}
