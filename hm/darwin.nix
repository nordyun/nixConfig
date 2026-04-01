{ pkgs, ... }:
{
  age.secrets = {
    pushover_token.file = ../secrets/pushover_token.age;
    pushover_user.file = ../secrets/pushover_user.age;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PATH = "$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools";
    ANDROID_HOME = "/Users/wash/Library/Android/sdk";
  };
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
