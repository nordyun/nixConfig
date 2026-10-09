{
  inputs,
  config,
  lib,
  pkgs,
  myLib,
  ...
}:
{
  users.users = {
    wash = {
      name = "wash";
      home = "/Users/wash";
      openssh.authorizedKeys.keyFiles = [ myLib.nordyunKeys ];
      shell = pkgs.${config.shellPreferences.wash};
    };
  };

  # nix-darwin only updates shells for knownUsers. Manage this existing account's
  # shell without placing the primary macOS account under its user lifecycle.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    if /usr/bin/id -u wash >/dev/null 2>&1; then
      /usr/bin/dscl . -create /Users/wash UserShell ${lib.escapeShellArg "/run/current-system/sw${config.users.users.wash.shell.shellPath}"}
    fi
  '';

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
      ../../hm/agents.nix
    ];
  };

  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.sharedModules = [
    inputs.agenix.homeManagerModules.default
  ];
}
