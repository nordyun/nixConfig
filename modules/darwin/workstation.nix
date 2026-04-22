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
      "tailscale-app"
      "raycast"
    ];
  };
  services.jankyborders = {
    enable = true;
    active_color = "gradient(top_left=0xffFF0000,bottom_right=0xff00FF00)";
    inactive_color = "0xff101010";
    hidpi = true;
    width = 6.0;
    # style = "round";
  };

  # aerospace installed via homebrew for now — configure via ~/.aerospace.toml
  # TODO: move back to services.aerospace once config is dialed in
}
