{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    brubsby-nixpkgs-local.url = "path:/home/tbusby/Repos/nixpkgs";
    brubsby-nixpkgs-github-yafu.url = "github:brubsby/nixpkgs/yafu";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    nixcord.url = "github:FlameFlag/nixcord";
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      sops-nix,
      nixos-hardware,
      treefmt-nix,
      nixcord,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    in
    {
      nixosConfigurations = {
        puter = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./configuration.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.tbusby = import ./home.nix;
              home-manager.sharedModules = [ inputs.nixcord.homeModules.nixcord ];
            }
          ];
        };
      };

      homeConfigurations = {
        tbusby = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            inputs.nixcord.homeModules.nixcord
            {
              nixpkgs.config.allowUnfree = true;
            }
          ];
        };
      };

      formatter.${system} = treefmtEval.config.build.wrapper;
    };
}
