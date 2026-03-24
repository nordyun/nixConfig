{ pkgs, myLib, config, ... }:
let
  unstable = myLib.mkUnstable pkgs;
in
{
  environment.shells = [ pkgs.fish ];
  environment.systemPackages = [ pkgs.jankyborders ];

  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    casks = [
      "font-hack-nerd-font"
      "font-fira-code-nerd-font"
      "sf-symbols"
      "karabiner-elements"
      "hiddenbar"
      "bluebubbles"
      "kodi"
      "calibre"
      "kitty"
      "wezterm"
      "font-jetbrains-mono"
    ];
  };

  # aerospace installed via homebrew for now — configure via ~/.aerospace.toml
  # TODO: move back to services.aerospace once config is dialed in
}
