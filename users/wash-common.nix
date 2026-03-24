{
  inputs,
  pkgs,
  config,
  myLib,
  ...
}:
{
  users.mutableUsers = false;

  home-manager.users.wash = { config, ... }: {
    home = {
      username = "wash";
      homeDirectory = "/home/wash";
      stateVersion = "23.11";
    };
    programs.home-manager.enable = true;
    age = {
      identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      secretsDir = "${config.home.homeDirectory}/.agenix/agenix";
      secretsMountPoint = "${config.home.homeDirectory}/.agenix/agenix.d";
    };
    imports = [
      ../hm
    ];
  };

  users.users.wash = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKisWeKbt3/lZL4HdPCTM9gXFsu+jkLg62ymJEQQpkN+ molly@Mollys-MacBook-Pro.local"
    ];
    openssh.authorizedKeys.keyFiles = [ myLib.nordyunKeys ];
    hashedPasswordFile = config.age.secrets.washpw.path;
    shell = pkgs.fish;
  };

  home-manager.sharedModules = [
    inputs.agenix.homeManagerModules.default
  ];

  age.secrets.washpw.file = ../secrets/washpw.age;
}
