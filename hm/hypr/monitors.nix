{ osConfig, ... }:
{
  wayland.windowManager.hyprland.extraConfig = ''
    monitor=DP-1,3840x2160@95.03,auto,1.6
    monitor=DP-3,3840x2160@95.03,auto,1.6
    monitor=HDMI-A-1,3840x2160@60,auto,1.6
    monitor=,preferred,auto,1
    workspace=10,monitor:HDMI-A-1,default:true
    ${osConfig.hostVars.extraMonitorSettings}
  '';
}
