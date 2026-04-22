{ pkgs, lib, ... }:
{
  programs.fish.interactiveShellInit = lib.mkIf pkgs.stdenv.isDarwin ''
    # Add nix binary paths to the PATH on Darwin
    fish_add_path --prepend --global "$HOME/.nix-profile/bin" /nix/var/nix/profiles/default/bin /run/current-system/sw/bin /opt/homebrew/bin /opt/homebrew/opt/ruby/bin "$HOME/.local/bin"
  '';
}
