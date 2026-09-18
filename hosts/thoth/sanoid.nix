{
  services.sanoid = {
    enable = true;

    templates.default = {
      yearly = 3;
      monthly = 6;
      weekly = 0;
      daily = 30;
      hourly = 0;
      frequently = 0;
      autosnap = true;
      autoprune = true;
    };
    templates.ignore = {
      autoprune = false;
      autosnap = false;
      monitor = false;
    };

    datasets = {
      "mercury" = {
        useTemplate = [ "default" ];
        recursive = true;
      };
      "mercury/obsidian".hourly = 48;
      "rpool" = {
        useTemplate = [ "default" ];
        recursive = true;
        processChildrenOnly = true;
      };
      "rpool/nix" = {
        useTemplate = [ "ignore" ];
        recursive = true;
      };
      "rpool/home".hourly = 48;
      "rpool/postgresql" = {
        hourly = 48;
        monthly = 3;
        yearly = 0;
      };
      "rpool/root" = {
        hourly = 24;
        daily = 14;
        monthly = 2;
        yearly = 0;
      };
      "rpool/var" = {
        hourly = 24;
        daily = 14;
        monthly = 2;
        yearly = 0;
      };
      "mercury/testUploads1".useTemplate = [ "ignore" ];
      "mercury/testUploads2".useTemplate = [ "ignore" ];
    };
  };
}
