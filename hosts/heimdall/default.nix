# OVH VPS: minimal bootstrap. See README.md before installation.
{ config, inputs, pkgs, myLib, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./monitoring.nix
  ];

  networking.hostName = "heimdall";
  time.timeZone = "America/New_York";
  system.stateVersion = "26.05";

  # Keep this host independent of the home-server defaults: those enable ZFS,
  # console autologin, desktop packages, and secrets not yet keyed to heimdall.
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    allowed-users = [ "root" "@wheel" ];
    trusted-users = [ "root" ];
    auto-optimise-store = true;
    max-jobs = 1;
    cores = 1;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.wash = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
    openssh.authorizedKeys.keyFiles = [ myLib.nordyunKeys ];
  };
  # Key-only administrator; required for unattended remote rebuilds as wash.
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    ports = [ 31225 ];
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";
      AllowUsers = [ "wash" ];
      X11Forwarding = false;
      AllowAgentForwarding = false;
    };
  };

  # Enroll interactively after the first boot. No shared home auth key needed.
  services.tailscale.enable = true;
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ config.services.tailscale.port ];
    # Do not trust the entire tailnet or expose a monitoring UI by default.
  };

  services.journald.extraConfig = ''
    SystemMaxUse=200M
    RuntimeMaxUse=50M
    MaxRetentionSec=14day
  '';

  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    htop
  ];
}
