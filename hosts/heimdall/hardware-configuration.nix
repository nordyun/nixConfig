# Based on the provisioned OVH VPS inspected from Debian 13.
# BIOS boot was confirmed via absence of /sys/firmware/efi.
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_scsi" "sd_mod" ];
  swapDevices = [ { device = "/swapfile"; size = 1024; } ];
}
