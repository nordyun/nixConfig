# horus — homelab observability / infra box (2012 Mac mini, headless).
# See ~/.claude/plans/alright-this-is-a-inherited-adleman.md for the full plan.
# Phase 0: boots off the flake, joins the tailnet, standalone monit agent.
# Phase 1+ adds ./mmonit.nix, ./nut.nix, ./librenms.nix, ./observability.nix.
{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./tailscale.nix
    ./monit.nix
    ./mmonit.nix
    ../../modules/common
    ../../users/wash
  ];

  networking = {
    hostName = "horus";
    hostId = "be275cd6"; # required: modules/common enables ZFS support
    networkmanager.enable = false;
  };

  time.timeZone = "America/New_York";

  hardware.enableRedistributableFirmware = true;

  # 2012 Mac mini firmware won't reliably persist a systemd-boot NVRAM entry;
  # rely on the removable EFI/BOOT/BOOTX64.EFI fallback that systemd-boot always
  # installs. Overrides modules/common/sys-default.nix (which sets this true).
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  system.stateVersion = "26.05";
}
