{
  description = "Gravity hardened nix-darwin system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
  let
    system = "aarch64-darwin";
    username = "gravity";
  in
  {
    darwinConfigurations."air" = nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit self inputs; };

      modules = [
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.${username} = import ./home.nix;
        }
        ./modules/system.nix
        ./modules/darwin.nix
      ];
    };
  };
}
