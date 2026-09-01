{ pkgs, inputs, myLib, ... }:
let
  unstable = myLib.mkUnstable pkgs;
in
{
  imports = [
    ../../modules/common/darwin-common.nix
    ../../modules/darwin/workstation.nix
    ../../users/darwin-wash
    inputs.agenix.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
  ];

  nixpkgs.hostPlatform = "x86_64-darwin";
  nixpkgs.config.allowUnfree = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  environment.systemPackages = with pkgs; [
    python3
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    unstable.eza
    unstable.pyenv
  ];

  homebrew.brews = [
    "cloudflare/cloudflare/cloudflared"
  ];

  # saturn-specific aerospace rules
  services.aerospace.settings.on-window-detected = [
    { "if".app-name-regex-substring = "Spark"; run = "move-node-to-workspace 4"; }
  ];

  system.stateVersion = 6;
}
