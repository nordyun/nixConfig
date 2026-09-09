{ pkgs, ... }:
let
  # The board has 3x Intel i225 NICs (igc driver). The real interface name is
  # not known until first boot - check `ip link` on thoth and update this.
  lanInterface = "enp1s0";
in
{
  imports = [
    ../../modules/common
    ./hardware-configuration.nix
    ./impermanence.nix
    ./hwaccel.nix
    ./sanoid.nix
    ./syncoid.nix
    ./systemdservices.nix
    ./tailscale.nix
    ../../users/wash
    ../../modules/server
  ];

  networking = {
    hostName = "thoth";
    networkmanager.enable = true;
  };

  time.timeZone = "America/New_York";

  # --- ZFS: takes over the "mercury" pool moved from anubis ---
  # First boot after attaching the disks: the pool still records anubis's
  # hostid, so import once with:  zpool import -f mercury
  # (ideally `zpool export mercury` on anubis before moving the drives).
  networking.hostId = "c0b08ea5";
  boot.zfs.extraPools = [ "mercury" ];
  services.zfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.mail.enable = false;
    notifications.wall.enable = true;
  };

  # Podman kept available even though nothing runs in it yet - n8n / letta may
  # come back later (they were left on anubis / dropped for now).
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # TEMP: immich 2.7.5 is EOL and flagged for CVE-2026-59258 / CVE-2026-82272.
  # No fixed version exists on nixos-26.05; immich 3.x lands in 26.11.
  # REMOVE this when upgrading to 26.11 (or moving immich to unstable) and
  # migrate to immich 3.x (Postgres schema migration - back up the DB first).
  nixpkgs.config.permittedInsecurePackages = [ "immich-2.7.5" ];

  services = {
    immich = {
      enable = true;
      port = 2283;
      host = "0.0.0.0";
      # NOTE: mediaLocation defaults to /var/lib/immich (NOT on mercury).
      # Decide where the immich library should live before importing data.
      # mediaLocation = "/mercury/immich/upload";
      openFirewall = true;
    };
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
    nfs.server = {
      enable = true;
      # fixed rpc.statd ports; for firewall
      lockdPort = 4001;
      mountdPort = 4002;
      statdPort = 4000;
      extraNfsdConfig = "";
    };
    samba = {
      enable = true;
      nmbd.enable = false;
      openFirewall = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "smbnix";
          "disable netbios" = "yes";
          "netbios name" = "smbnix";
          "security" = "user";
          "hosts allow" = "10.1.1. 100. 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
          # Protocol - force SMB3
          "server min protocol" = "SMB3";
          "server max protocol" = "SMB3";
          # macOs finder optimizations
          "vfs objects" = "catia fruit streams_xattr";
          "fruit:metadata" = "stream";
          "fruit:model" = "MacSamba";
          "fruit:posix_rename" = "yes";
          "fruit:nfs_aces" = "no";
          "fruit:veto_appledouble" = "no";
          "fruit:wipe_intentionally_left_blank_rfork" = "yes";
          "fruit:delete_empty_adfiles" = "yes";
          # Performance
          "aio read size" = "1";
          "aio write size" = "1";
        };
        "music" = {
          "path" = "/mercury/music";
          "valid users" = "wash";
          "public" = "no";
          "browseable" = "yes";
          "read only" = "yes";
          "guest ok" = "no";
          "force user" = "wash";
        };
        "photos" = {
          "path" = "/mercury/photos";
          "valid users" = "wash";
          "public" = "no";
          "browseable" = "yes";
          "read only" = "yes";
          "guest ok" = "no";
          "force user" = "wash";
        };
        "movies" = {
          "path" = "/mercury/movies";
          "valid users" = "wash";
          "public" = "no";
          "browseable" = "yes";
          "read only" = "yes";
          "guest ok" = "no";
          "force user" = "wash";
        };
        "homevids" = {
          "path" = "/mercury/homevids";
          "valid users" = "wash";
          "public" = "no";
          "browseable" = "yes";
          "read only" = "yes";
          "guest ok" = "no";
          "force user" = "wash";
        };
        "tv" = {
          "path" = "/mercury/tv";
          "valid users" = "wash";
          "public" = "no";
          "browseable" = "yes";
          "read only" = "yes";
          "guest ok" = "no";
          "force user" = "wash";
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    dive # inspect docker/podman image layers
    podman-tui # container status
    docker-client
  ];

  networking.firewall.interfaces.${lanInterface} = {
    allowedTCPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
      31225 # ssh (openssh openFirewall = false in modules/common)
    ];
    allowedUDPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
    ];
  };

  system.stateVersion = "26.05";
}
