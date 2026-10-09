{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./sys-default.nix
    ./shells.nix
    #    ./noexec.nix
    ./agenix.nix
    ../host-variables.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    nerd-fonts.fira-code
  ];
}
