{ pkgs, myLib, ... }:
let
  unstable = myLib.mkUnstable pkgs;
in
{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix
    ./sanoid.nix
    ./syncoid.nix
    ./systemdservices.nix
    ./monit.nix
    ./autologin.nix
    ./tailscale.nix
    ./upmpdcli.nix
    ./camilladsp.nix
    ./camillagui.nix
    ./camillaeq.nix
    ./n8n.nix
    ./letta.nix
    ./tws.nix
    ../../modules/common
    ../../users/wash-desktop
    ../../modules/desktop/hyprwm.nix
    ../../modules/desktop/android.nix
    ../../modules/server
    ../../modules/snmpd.nix
  ];

  networking = {
    hostName = "anubis";
    networkmanager.enable = true;
  };

  time.timeZone = "America/New_York";

  modules.android.enable = true;

  # Host-specific variables for Hyprland/desktop
  hostVars = {
    browser = "microsoft-edge";
    terminal = "kitty";
    keyboardLayout = "us";
    consoleKeyMap = "us";
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  #For ZFS support
  networking.hostId = "fd91c922";
  # services.zfs.autoScrub = {
  #   enable = true;
  #   interval = "monthly";
  # };
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.mail.enable = false;
    notifications.wall.enable = true;
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  services = {
    lact.enable = true;
    mpd = {
      enable = true;
      settings = {
        music_directory = "/mercury/music";
        audio_output = [
          {
            type = "alsa";
            name = "Bitperfect (Direct)";
            device = "hw:0,0";
            auto_resample = "no";
            auto_channels = "no";
            auto_format = "no";
            dop = "no";
            buffer_time = "200000";
            period_time = "50000";
            enabled = "yes";
          }
          {
            type = "alsa";
            name = "CamillaDSP EQ";
            device = "camilladsp";
            auto_resample = "no";
            auto_channels = "no";
            auto_format = "no";
            buffer_time = "200000";
            period_time = "50000";
            enabled = "no";
          }
          {
            type = "fifo";
            name = "my_fifo";
            path = "/tmp/mpd.fifo";
            format = "44100:16:2";
          }
        ];
        resampler = [
          {
            plugin = "soxr";
            quality = "very high";
          }
        ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    obsidian
    dive # look into docker image layers
    podman-tui # container status
    docker-client
    lact
    makemkv
    chromium
    firefox
    pamixer
    pwvucontrol
    ncmpcpp
    whipper
    picard
  ];
  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = ["multi-user.target"];

  networking.firewall.interfaces."enp5s0" = {
    allowedTCPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
      31225
    ];
    allowedUDPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
      31225
    ];
  };
  system.stateVersion = "23.11";
}
