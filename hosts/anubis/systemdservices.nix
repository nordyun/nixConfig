{ pkgs, ... }:
{
  systemd.timers.rcloneOnedrive = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*~01 22:00";
      Persistent = true;
      Unit = "rcloneOnedrive.service";
    };
  };
  systemd.services.rcloneOnedrive = {
    enable = true;
    after = [ "network.target" ];
    description = "Monthly photo backup to Onedrive";
    path = [ "/run/current-system/sw" ];
    serviceConfig = {
      Type = "oneshot";
      # ExecStart = [
      #   "/home/wash/linuxbin/rcloneOnedrive.sh"
      #   "/home/wash/linuxbin/rcloneMusic.sh"
      # ];
      User = "wash";
      Group = "users";
    };
    script = ''
      ${./rcloneOnedrive.sh}
      '';
  };
  systemd.user.services.wayvnc = {
    enable = true;
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    description = "Automatically start Wayvnc";
    serviceConfig = {
      Type = "simple";
      ExecStart = ''${pkgs.wayvnc}/bin/wayvnc 0.0.0.0 -o HDMI-A-1'';
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
  # systemd.user.services.maestral = {
  #   Unit = {
  #     Description = "Maestral Dropbox client";
  #     After = [ "network-online.target" ];   
  #   };
  #   Service = {
  #     ExecStart = "${pkgs.maestral}/bin/maestral start --foreground";
  #     Restart = "on-failure";
  #     RestartSec = "5s";
  #   };
  #     wantedBy = [ "default.target"];
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
  systemd.services.jellyfin.environment.HOME = "/var/cache/jellyfin";

  age.secrets.pushover_user.file = ../../secrets/pushover_user.age;
  age.secrets.pushover_token.file = ../../secrets/pushover_token.age;
}
