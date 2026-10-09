{ pkgs, lib, ... }:
{
  imports = [
    common/cli.nix
    common/mcp.nix
    common/shell
    common/nvim
  ];
  home.file."./bin" = lib.mkIf pkgs.stdenv.isLinux {
    source = ./linuxbin;
    recursive = true;
  };
  # home.file.".config/kitty" = lib.mkIf pkgs.stdenv.isLinux {
  #   source = ./common/kitty;
  #   recursive = true;
  # };
}
