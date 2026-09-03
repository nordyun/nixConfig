{ config, pkgs, lib, ... }:

let
  # Build the package chain
  libnpupnp = pkgs.callPackage ../../pkgs/libnpupnp.nix {};
  libupnpp = pkgs.callPackage ../../pkgs/libupnpp.nix { inherit libnpupnp; };
  upmpdcli = pkgs.callPackage ../../pkgs/upmpdcli.nix { inherit libupnpp; };

  # Config file template (secrets injected at runtime)
  configTemplate = pkgs.writeText "upmpdcli.conf.template" ''
    # UPnP settings
    friendlyname = Anubis MPD
    upnpiface = enp5s0
    upnpav = 1
    openhome = 1
    checkcontentformat = 1

    # MPD connection
    mpdhost = localhost
    mpdport = 6600

    # Qobuz plugin
    qobuzuser = @QOBUZ_USER@
    qobuzpass = @QOBUZ_PASS@
    qobuzformatid = 27

    # Plugin path
    pluginspath = ${upmpdcli}/share/upmpdcli/cdplugins
  '';
in
{
  # Declare the secrets
  age.secrets.qobuz_user = {
    file = ../../secrets/qobuz_user.age;
    owner = "upmpdcli";
    group = "upmpdcli";
  };
  age.secrets.qobuz_pass = {
    file = ../../secrets/qobuz_pass.age;
    owner = "upmpdcli";
    group = "upmpdcli";
  };

  # Create system user for upmpdcli
  users.users.upmpdcli = {
    isSystemUser = true;
    group = "upmpdcli";
    extraGroups = [ "audio" ];
  };
  users.groups.upmpdcli = {};

  # Systemd service
  systemd.services.upmpdcli = {
    description = "UPnP Media Renderer front-end for MPD";
    after = [ "network.target" "mpd.service" ];
    wants = [ "mpd.service" ];
    wantedBy = [ "multi-user.target" ];

    # openssl: OHCredentials RSA key generation
    # pythonEnv: OHRadio looks for `python3` on PATH; radio_scripts need `requests`
    path = [ pkgs.openssl upmpdcli.pythonEnv ];

    serviceConfig = {
      Type = "simple";
      User = "upmpdcli";
      Group = "upmpdcli";
      StateDirectory = "upmpdcli";
      RuntimeDirectory = "upmpdcli";
      CacheDirectory = "upmpdcli";

      ExecStartPre = pkgs.writeShellScript "upmpdcli-config" ''
        # Generate config with secrets
        ${pkgs.gnused}/bin/sed \
          -e "s|@QOBUZ_USER@|$(cat ${config.age.secrets.qobuz_user.path})|g" \
          -e "s|@QOBUZ_PASS@|$(cat ${config.age.secrets.qobuz_pass.path})|g" \
          ${configTemplate} > /run/upmpdcli/upmpdcli.conf
        chmod 600 /run/upmpdcli/upmpdcli.conf
      '';

      ExecStart = "${upmpdcli}/bin/upmpdcli -c /run/upmpdcli/upmpdcli.conf";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Open firewall for UPnP
  networking.firewall = {
    allowedTCPPorts = [ 49152 49153 ];
    allowedUDPPorts = [ 1900 ];
  };

  # Make the package available
  environment.systemPackages = [ upmpdcli ];
}
