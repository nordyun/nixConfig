{
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./router.nix
    ./unbound.nix
    ./tailscale.nix
    ./monit.nix
    ../../modules/common
    ../../users/wash
    ../../modules/server
    # cloudflare
  ];

  networking = {
    hostId = "ca0bad48";
    hostName = "neptune";
    networkmanager.enable = false;
  };

  time.timeZone = "UTC";

  boot.kernelParams = [ "nohibernate" ];

  system.stateVersion = "23.11";
}
