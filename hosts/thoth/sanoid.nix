{
  services.sanoid = {
    enable = true;
    templates.photo = {
      yearly = 3;
      monthly = 6;
      daily = 30;
      hourly = 0;
      autosnap = true;
      autoprune = true;
    };
    templates.ignore = {
      autoprune = false;
      autosnap = false;
    };
    datasets."mercury/photos".useTemplate = [ "photo" ];
    datasets."mercury/homevids".useTemplate = [ "photo" ];
    datasets."mercury/mollyimages".useTemplate = [ "photo" ];
    datasets."mercury/vids".useTemplate = [ "photo" ];
    datasets."mercury/movies".useTemplate = [ "photo" ];
    datasets."mercury/music".useTemplate = [ "photo" ];
    datasets."mercury/tv".useTemplate = [ "photo" ];
    datasets."mercury/dadmusic".useTemplate = [ "photo" ];

  };
}
