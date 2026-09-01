{ inputs, pkgs, ... }:
{
  imports = [
    ./settings.nix
    ./appearance.nix
    ./keybinds.nix
    ./rules.nix
    ./environment.nix
    ./monitors.nix
    ./waybar.nix
    ./components/packages.nix
    ./components/systemd-services.nix
    ./components/resources.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    xwayland = {
      enable = true;
    };
    systemd.enable = false;
    plugins = [
      (pkgs.hyprlandPlugins.mkHyprlandPlugin {
        pluginName = "hyprtasking";
        version = "0-unstable-2026-06-28";
        src = inputs.hyprtasking;
        nativeBuildInputs = [ pkgs.meson pkgs.ninja ];
        # meson.build asks for pixman-1 explicitly; the rest come from
        # hyprland.buildInputs via mkHyprlandPlugin.
        buildInputs = [ pkgs.pixman ];
        meta.description = "Workspace management plugin for Hyprland";
      })
    ];
    settings = {
      exec-once = [
        # "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        # "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        # waybar is now managed via systemd (programs.waybar.systemd.enable = true)
        "killall -q swaync;sleep .5 && swaync"
        # "waytrogen -r"
        "awww-daemon"
      ];
    };
  };
}
