{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    wofi
    nemo
    _1password-gui
    swaynotificationcenter
    # wayvnc
    maestral
    maestral-gui
    waytrogen
    mpvpaper
    inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
