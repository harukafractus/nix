{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable/";
    nixpkgs-stable-linux.url = "github:NixOS/nixpkgs/release-26.05";
    nixpkgs-stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    haruka-nur = {
      url = "github:fractuscontext/nix-nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable-linux,
      nixpkgs-stable-darwin,
      home-manager,
      nix-darwin,
      mac-app-util,
      haruka-nur,
      ...
    }@inputs:
    let
      username = "tsubasa";
      hostname = "CONSUMERISM";
      darwinSystem = "aarch64-darwin";
      pkgs-unstable-linux = nixpkgs.legacyPackages.x86_64-linux;
      pkgs-stable-linux = nixpkgs-stable-linux.legacyPackages.x86_64-linux;
      pkgs-stable-darwin = nixpkgs-stable-darwin.legacyPackages.${darwinSystem};

      pkgs-haruka-darwin = import nixpkgs {
        system = darwinSystem;
        overlays = [ haruka-nur.overlays.mac-apps ];
      };
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = { inherit inputs username hostname; };
        modules = [
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          ./configs/darwin.nix
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit username pkgs-haruka-darwin pkgs-stable-darwin; };
            home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];
            home-manager.users.${username} = import ./configs/home.nix;
          }
        ];
      };

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs-unstable-linux;
        extraSpecialArgs = { inherit username pkgs-stable-linux; };
        modules = [ ./configs/home.nix ];
      };
    };
}
