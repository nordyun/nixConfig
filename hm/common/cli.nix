{ config, pkgs, ... }:
{
  config = {
    # home.file.".config/kitty".source = ./kitty;
    # moved kitty to stow
    home.file.".npmrc".text = ''
      prefix=${config.home.homeDirectory}/.npm-global
    '';
    home.sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];

    home.packages = with pkgs; [
      bat
      curl
      fd
      file
      fzf
      git
      neofetch
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
      zoxide
    ];

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
    #    age.secrets.miniIp.file = ../../secrets/miniIp.age;

    programs = {
      kitty = {
        enable = pkgs.stdenv.isLinux; #macos install via homebrew for notifications
      };
      bat = {
        enable = true;
        # config.theme = "Dracula";
      };
      fzf = {
        enable = true;
        enableZshIntegration = true;
        defaultOptions = [
          "--height 40%"
          "--layout=reverse"
          "--border"
          "--inline-info"
        ];
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
      zsh = {
        enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;
      };
      nushell = {
        enable = true;
      };
      carapace = {
        enable = true;
        enableNushellIntegration = true;
      };
      starship = {
        enable = true;
      };
      neovim = {
        enable = true;
        defaultEditor = true;
      };
      atuin = {
        enable = true;
        settings = {
          key_path = config.age.secrets.atuinKey.path;
          enter_accept = true;
          #        sync_address = "https://majiy00-shell.fly.dev";
        };
      };
      zoxide = {
        enable = true;
        enableFishIntegration= true;
        enableNushellIntegration = true;
        enableZshIntegration = true;
      };
    };
    age.secrets.atuinKey.file = ../../secrets/atuinKey.age;
  };
}
