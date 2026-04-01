{ pkgs, config, myLib, ... }:
let
  unstable = myLib.mkUnstable pkgs;
in
{
  imports = [ ../host-variables.nix ];

  programs.gnupg.agent.enable = true;
  #  programs.zsh.enable = true;
  #  environment.pathsToLink = [ "/share/zsh" ];
  nix.package = pkgs.nixVersions.stable;
  nix.settings.cores = 0; # use all cores
  nix.settings.max-jobs = 10; # use all cores
  environment.systemPath = [ "/opt/homebrew/bin" ];
  programs.fish.enable = true;
  system.primaryUser = config.hostVars.primaryUser;
  system.defaults = {
    NSGlobalDomain.AppleShowAllExtensions = true;
    NSGlobalDomain.InitialKeyRepeat = 25;
    NSGlobalDomain.KeyRepeat = 4;
    NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
    NSGlobalDomain.PMPrintingExpandedStateForPrint = true;
    NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
    NSGlobalDomain."com.apple.trackpad.trackpadCornerClickBehavior" = 1;
    dock.autohide = true;
    dock.mru-spaces = false;
    dock.show-recents = false;
    dock.static-only = true;
    finder.AppleShowAllExtensions = true;
    finder.FXEnableExtensionChangeWarning = false;
    loginwindow.GuestEnabled = false;
    screencapture.disable-shadow = true;
    screencapture.location = "${config.hostVars.homeDirectory}/Dropbox/Screenshots/io/2026/";
  };
  environment.systemPackages = [
    unstable.lua5_5
  ];
}
