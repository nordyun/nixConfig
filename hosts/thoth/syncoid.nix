# /usr/sbin/syncoid -r --skip-parent --no-privilege-elevation -sshport=31225 wash@andromeda:io mercury
{ config, options, ... }:
{
  services.syncoid = {
    enable = true;
    # commonArgs = [ "--skip-parent" "--recursive" ];
    # interval = "*-*-* 13:00:00";
    # commands."io_backup" = {
    #   sshKey = config.age.secrets.syncoidKey.path;
    #   extraArgs = [ "-sshport=31225" "--sshconfig=/run/agenix/syncoidConf" ];
    #   source = "wash@andromeda:io";
    #   target = "mercury";
    # };
    localTargetAllow = options.services.syncoid.localTargetAllow.default ++ [
      "destroy"
    ];
  };
  age.secrets = {
    syncoidKey = {
      file = ../../secrets/syncoidKey.age;
      owner = "syncoid";
      group = "syncoid";
    };
    syncoidConf = {
      file = ../../secrets/syncoidConf.age;
      owner = "syncoid";
      group = "syncoid";
    };
    syncoidKH = {
      file = ../../secrets/syncoidKH.age;
      owner = "syncoid";
      group = "syncoid";
    };
  };
}
