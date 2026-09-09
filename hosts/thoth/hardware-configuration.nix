# PLACEHOLDER - regenerate on the real hardware during install:
#
#   nixos-generate-config --root /mnt --no-filesystems
#
# then reconcile the generated kernel modules here and fill in the real
# by-uuid devices below. The impermanence layout (tmpfs root + btrfs subvols)
# must be created by the installer to match `fileSystems` - see hosts/anubis
# for the working model. Expected btrfs subvols on the root disk:
#   ssh (-> /etc/ssh), home, nix, persist
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [
    "kvm-intel"
    "sg" # generic SCSI - makemkv/whipper used this on anubis; harmless to keep
  ];
  boot.extraModulePackages = [ ];

  # tmpfs root (impermanence) - wiped every boot
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "size=3G"
      "mode=755"
    ];
  };

  # --- TODO: replace REPLACE-ME with the real root-disk UUID after install ---
  fileSystems."/etc/ssh" = {
    device = "/dev/disk/by-uuid/REPLACE-ME";
    fsType = "btrfs";
    options = [
      "subvol=ssh"
      "compress=zstd"
      "noatime"
    ];
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/REPLACE-ME";
    fsType = "btrfs";
    options = [
      "subvol=home"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/REPLACE-ME";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "compress=zstd"
      "noatime"
    ];
    neededForBoot = true;
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/REPLACE-ME";
    fsType = "btrfs";
    options = [
      "subvol=persist"
      "compress=zstd"
      "noatime"
    ];
    neededForBoot = true;
  };

  # --- TODO: replace with the real EFI System Partition UUID ---
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-ME";
    fsType = "vfat";
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
