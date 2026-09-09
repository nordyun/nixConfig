{ ... }:
{
  # Monthly pull of phone photos from OneDrive -> /mercury/{photos,homevids},
  # then push /mercury/music back up to OneDrive. Needs, on thoth:
  #   - an `onedrive:` rclone remote configured for user wash
  #   - the pushover_{user,token} agenix secrets (declared below)
  #   - ~/bin/pushover.sh (provided by home-manager, hm/linuxbin)
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
      User = "wash";
      Group = "users";
    };
    script = ''
      ${./rcloneOnedrive.sh}
    '';
  };

  systemd.services.jellyfin.environment.HOME = "/var/cache/jellyfin";

  age.secrets.pushover_user.file = ../../secrets/pushover_user.age;
  age.secrets.pushover_token.file = ../../secrets/pushover_token.age;
}
