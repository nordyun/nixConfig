{
  description = "Wash's nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    llm-agents.url = "github:numtide/llm-agents.nix";
    # Hyprland itself comes from nixpkgs (cached). hyprtasking is built against
    # pkgs.hyprland via pkgs.hyprlandPlugins.mkHyprlandPlugin, so we only need
    # its source here. Pinned to the revision hyprpm.toml maps to Hyprland
    # v0.55.4 (nixpkgs 26.05); bump when nixpkgs bumps Hyprland.
    hyprtasking = {
      url = "github:raybbian/hyprtasking/765575445ce34989575a99f304d0b279e6a980b6";
      flake = false;
    };
    hyprwm-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    eww = {
      url = "github:elkowar/eww";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      darwin,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      llm-agents,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      myLib = import ./lib { inherit inputs; };
    in
    {
      nixosConfigurations = {
        anubis = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs myLib; };
          modules = [
            ./hosts/anubis
          ];
        };
        neptune = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs myLib; };
          modules = [
            ./hosts/neptune
          ];
        };
        zelda = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs myLib; };
          modules = [
            ./hosts/zelda
          ];
        };
        nixmacVM = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs myLib; };
          modules = [
            ./hosts/nixmacVM
          ];
        };
      };
      darwinConfigurations = {
        io = darwin.lib.darwinSystem {
          specialArgs = { inherit inputs outputs myLib; };
          modules = [
            ./hosts/io
          ];
        };
        anu = darwin.lib.darwinSystem {
          specialArgs = { inherit inputs outputs myLib; };
          modules = [
            ./hosts/anu
          ];
        };
        saturn = darwin.lib.darwinSystem {
          specialArgs = { inherit inputs outputs myLib; };
          modules = [
            ./hosts/saturn
          ];
        };
      };
    };
}
