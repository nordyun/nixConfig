{ pkgs, inputs, ... }:
{
  imports = [
    ../../modules/common/darwin-common.nix
    ../../modules/darwin/workstation.nix
    ../../users/darwin-wash
    inputs.agenix.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
  ];

  nix.enable = false; # for determinate nix install
  nix.settings.lazy-trees = true;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.android_sdk.accept_license = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  environment.systemPackages = with pkgs; [
    python3
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    eza
    pyenv
    iina
    nixfmt
    jdk17
  ];

  homebrew.taps = [
    "supabase/tap"
  ];
  homebrew.brews = [
    #        "cloudflared"
    "anomalyco/tap/opencode"
    "dlvhdr/formulae/diffnav"
    "acsandmann/tap/rift"
    "ruby"
    "rustledger"
    "supabase"
    "xcodegen"
    "coreutils"
    "poppler"
    "tag"
  ];
  homebrew.casks = [
    "wallspace"
    "termius"
  ];

  # casks moved to workstation.nix
  # homebrew.casks = [
  #   # "hammerspoon"
  # ];


  services.sketchybar = {
    enable = true;
    package = pkgs.sketchybar;
  };

  system.stateVersion = 6;
}
