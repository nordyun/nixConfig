{ inputs, pkgs, myLib, ... }:
{
  environment.shells = [ pkgs.fish ];
  users.users = {
    wash = {
      name = "wash";
      home = "/Users/wash";
      openssh.authorizedKeys.keyFiles = [ myLib.nordyunKeys ];
      shell = pkgs.fish;
    };
  };

  home-manager.users.wash = { config, ... }: {
    programs.home-manager.enable = true;
    home = {
      username = "wash";
      homeDirectory = "/Users/wash";
      stateVersion = "24.11";
    };
    age = {
      identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      secretsMountPoint = "${config.home.homeDirectory}/.agenix/agenix.d";
      secretsDir = "${config.home.homeDirectory}/.agenix/agenix";
    };
    imports = [
      ../../hm
      ../../hm/darwin.nix
    ];
  };

  home-manager.sharedModules = [
    inputs.agenix.homeManagerModules.default
  ];
}
