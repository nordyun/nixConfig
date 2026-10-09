{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
in
{
  imports = [
    ./fish.nix
    ./zsh.nix
    ./desktop-session.nix
  ];

  home.sessionPath = [
    "${homeDir}/bin"
    "${homeDir}/.local/bin"
    "${homeDir}/.cargo/bin"
    "${homeDir}/.npm-global/bin"
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    "/opt/homebrew/opt/ruby/bin"
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
  home.shellAliases = {
    v = "nvim";
    vim = "nvim";
    gpl = "git pull";
    gp = "git push";
    lg = "lazygit";
    gc = "git commit -v";
    gs = "git status -v";
    gl = "git log --graph";
    l = "eza -la --git";
    la = "eza -la --git";
    ls = "eza";
    ll = "eza -l --git";
    cat = "bat";
    ".." = "cd ../";
    "..." = "cd ../..";
    "...." = "cd ../../..";
  };

  # Integrations apply to all configured shells, regardless of the login shell.
  programs = {
    nushell.enable = true;
    fzf = {
      enable = true;
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
      ];
    };
    carapace.enable = true;
    starship.enable = true;
    zoxide.enable = true;
    atuin = {
      enable = true;
      settings = {
        key_path = config.age.secrets.atuinKey.path;
        enter_accept = true;
      };
    };
  };
  age.secrets.atuinKey.file = ../../../secrets/atuinKey.age;
}
