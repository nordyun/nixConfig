{ ... }:
{
  # Enable dconf for GTK applications (needed for apps like waytrogen)

  hostVars.hyprlandAutoStart = true;

  programs = {
    dconf.enable = true;
    hyprland = {
      enable = true;
      withUWSM = true;
    };
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };
}
