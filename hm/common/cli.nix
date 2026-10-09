{ config, pkgs, ... }:
{
  config = {
    # home.file.".config/kitty".source = ./kitty;
    # moved kitty to stow
    home.file.".npmrc".text = ''
      prefix=${config.home.homeDirectory}/.npm-global
    '';

    home.packages = with pkgs; [
      bat
      curl
      fd
      file
      git
      fastfetch
      ripgrep
      unzip
      pv
      killall
      aria2
      meslo-lgs-nf
      nodejs # required for copilot
      nil
      lua-language-server
      # python313Packages.python-lsp-server  #failing on macos
      bash-language-server
      yaml-language-server
      typescript-language-server
      rust-analyzer
      pyright
      btop
      jq
      gh
      stow
    ];

    #    age.secrets.miniIp.file = ../../secrets/miniIp.age;

    programs = {
      # kitty = {
      # enable = pkgs.stdenv.isLinux; #macos install via homebrew for notifications
      # };
      bat = {
        enable = true;
        # config.theme = "Dracula";
      };
      git = {
        enable = true;
        lfs.enable = true;
        settings = {
          commit.gpgSign = false;
          user.name = "nordyun";
          user.email = "njorthson@proton.me";
          pull.ff = "only";
        };
      };
      neovim = {
        enable = true;
        defaultEditor = true;
      };
    };
  };
}
