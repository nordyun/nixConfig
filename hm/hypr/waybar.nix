{ config, ... }:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = "${config.xdg.configHome}/waybar/style.css";
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 25;
        modules-left = [
          "hyprland/workspaces"
          "hyprland/submap"
        ];
        modules-center = [
          "hyprland/window"
        ];
        modules-right = [
          "wlr/taskbar"
          # "custom/wireguard"
          "network"
          "pulseaudio"
          "cpu"
          "clock"
        ];
        "hyprland/workspaces" = {
          disable-scroll = true;
          format = "{icon}";
          all-outputs = true;
          format-icons = {
            "1" = "";  # code icon
            "2" = "";  # web icon
            "3" = "";  # terminal icon
            "4" = "";  # email icon
          };
        };
        "hyprland/window" = {
          format = "{title}";
        };
      };
    };
  };
}
