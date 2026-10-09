{ config, pkgs, ... }:
let
  androidHome = "${config.home.homeDirectory}/Library/Android/sdk";
in
{
  age.secrets = {
    pushover_token.file = ../secrets/pushover_token.age;
    pushover_user.file = ../secrets/pushover_user.age;
  };
  home.sessionPath = [
    "${androidHome}/tools"
    "${androidHome}/tools/bin"
    "${androidHome}/platform-tools"
  ];
  home.sessionVariables.ANDROID_HOME = androidHome;
  home.packages = with pkgs; [
    mosh
    nmap
    rclone
    rsync
    openssh
    mas

    #    pyenv            #only in unstable, hm problems, moved to system
    #    jq               #don't think i need this
    #    youtube-dl
    #    media-downloader #gui haven't tried it
  ];
  home.file."./bin" = {
    source = ./macbin;
    recursive = true;
  };
}
