{ lib, pkgs, ... }:
{
  options.shellPreferences = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.enum [
        "fish"
        "zsh"
      ]
    );
    default = { };
    description = "Login shell for each user; independent of the shells configured by Home Manager.";
  };

  config = {
    shellPreferences = {
      wash = lib.mkDefault "zsh";
      wyatt = lib.mkDefault "fish";
    };

    environment.shells = [
      pkgs.fish
      pkgs.zsh
    ];
    programs.fish.enable = true;
    programs.zsh = {
      enable = true;
      # Home Manager initializes completion after adding the user's fpath.
      enableCompletion = false;
    };
  };
}
