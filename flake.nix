{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable/";
    
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    
    haruka-nur.url = "github:fractuscontext/nix-nur";
    
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.cl-nix-lite.url = "github:r4v3n6101/cl-nix-lite/url-fix";
    };
  };

  outputs = { self, nixpkgs, haruka-nur, home-manager, mac-app-util, ... }@attrs:
    let
      username = "haruka";
      darwin-workstation = "apple-seeds";
      nixos-workstation = "kool-pc";
    in {
      darwinConfigurations.${darwin-workstation} = attrs.nix-darwin.lib.darwinSystem {
        modules = [
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          { nixpkgs.overlays = [ haruka-nur.overlays.mac-apps ]; } 
          { home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];}
          (import ./configs/darwin.nix {
            inherit darwin-workstation;
            inherit username;
          })
        ];
      };
    };
}
