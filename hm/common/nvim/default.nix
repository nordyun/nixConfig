{ pkgs, lib, ... }:
{
  home.file.".config/nvim" = {
    source = ./config;
    recursive = true;
  };

  programs.neovim = {
    enable = true;
    withRuby = true;
    withPython3 = true;
    extraPackages = with pkgs; [
      tree-sitter
      gcc
    ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      wl-clipboard
    ];
    extraConfig = ''
      set runtimepath^=~/.config/nvim
      lua dofile('${./config/init.lua}')
    '';
    vimAlias = true;
    viAlias = true;
    plugins = map (x: { plugin = x; }) (
      with pkgs.vimPlugins;
      [
        # vim-tmux-navigator
        # galaxyline-nvim
        nvim-web-devicons
        rainbow-delimiters-nvim
        # vista-vim
        # polyglot
        # vim-commentary # replaced with mini and acutally built-in now
        # vim-nix  # trying treesitter version
        # gruvbox
        incsearch-vim
        # vim-highlightedyank
        # vim-fugitive
        fzf-vim
        lualine-nvim
        fzf-wrapper
        # vim-devicons
        # toggleterm-nvim
        copilot-lua
        # new plugins testing
        twilight-nvim
        zen-mode-nvim
        nvim-dap # needs work
        nvim-dap-ui
        nvim-dap-virtual-text
        transparent-nvim
        gitsigns-nvim
        telescope-nvim
        nvim-treesitter.withAllGrammars
        trouble-nvim
        obsidian-nvim
        # harpoon
        mini-nvim
        nvim-cmp
        cmp-nvim-lsp
        noice-nvim
        catppuccin-nvim
        gruvbox
        git-worktree-nvim
        nvim-lspconfig
        fidget-nvim
        nvim-notify
      ]
    );
  };
}
