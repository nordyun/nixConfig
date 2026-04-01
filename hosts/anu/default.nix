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

  nix.enable = false; # for determinate nix install
  nix.settings.lazy-trees = true;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.android_sdk.accept_license = true;
  nixpkgs.overlays = [
    inputs.llm-agents.overlays.default
  ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  environment.systemPackages = with pkgs; [
    python3
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    eza
    pyenv
    iina
    nixfmt-rfc-style
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
