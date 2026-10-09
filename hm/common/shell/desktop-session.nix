{
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  uwsm = "${pkgs.uwsm}/bin/uwsm";
  start = "${uwsm} start ${osConfig.programs.hyprland.package}/bin/start-hyprland";
in
{
  config = lib.mkIf (pkgs.stdenv.isLinux && osConfig.hostVars.hyprlandAutoStart) {
    programs.fish.loginShellInit = ''
      if status is-interactive; and test (tty) = /dev/tty1; and ${uwsm} check may-start
        exec ${start}
      end
    '';
    programs.zsh.loginExtra = ''
      if [[ -o interactive && "$(tty)" == /dev/tty1 ]] && ${uwsm} check may-start; then
        exec ${start}
      fi
    '';
  };
}
