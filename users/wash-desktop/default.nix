{ ... }:
{
  imports = [ ../wash-common.nix ];

  # Desktop-specific: add hyprland config
  home-manager.users.wash.imports = [
    ../../hm/hypr
    ../../hm/qt.nix
    ../../hm/music
    ../../hm/agents.nix
  ];
}
