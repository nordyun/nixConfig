{
  inputs,
  pkgs,
  config,
  myLib,
  ...
}:
{
  users.mutableUsers = false;
  home-manager.users.wyatt = { config, ... }: {
    home = {
      username = "wyatt";
      homeDirectory = "/home/wyatt";
      stateVersion = "23.11";
    };
    programs.home-manager.enable = true;
    # nixpkgs.config.allowUnfree = true;
    age = {
      identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      secretsDir = "${config.home.homeDirectory}/.agenix/agenix";
      secretsMountPoint = "${config.home.homeDirectory}/.agenix/agenix.d";
    };
    imports = [
      ../../hm
      ../../hm/gnome.nix
    ];
  };

  home-manager.sharedModules = [
    inputs.agenix.homeManagerModules.default
  ];

  users.users = {
    wyatt = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      openssh.authorizedKeys.keyFiles = [ myLib.nordyunKeys ];
      hashedPasswordFile = config.age.secrets.wyattpw.path;
      shell = pkgs.fish;
      packages = with pkgs; [
        firefox
        tree
        kodi
        _1password-gui
      ];
    };
  };
  age.secrets.wyattpw.file = ../../secrets/wyattpw.age;
}
