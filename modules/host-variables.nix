{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.hostVars = {
    primaryUser = lib.mkOption {
      type = lib.types.str;
      default = "wash";
      description = "Primary user for this system";
    };
    homeDirectory = lib.mkOption {
      type = lib.types.str;
      default =
        let
          prefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";
        in
        "${prefix}/${config.hostVars.primaryUser}";
      description = "Home directory for the primary user (auto-computed from platform)";
    };
    hyprlandAutoStart = lib.mkEnableOption "starting Hyprland through UWSM on an interactive TTY1 login";
    extraMonitorSettings = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Extra Hyprland monitor configuration";
    };
    clock24h = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use 24-hour clock format in waybar";
    };
    browser = lib.mkOption {
      type = lib.types.str;
      default = "firefox";
      description = "Default browser command";
    };
    terminal = lib.mkOption {
      type = lib.types.str;
      default = "kitty";
      description = "Default terminal emulator command";
    };
    keyboardLayout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Keyboard layout for Hyprland";
    };
    consoleKeyMap = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Console keymap";
    };
  };
}
