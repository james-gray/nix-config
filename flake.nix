{
  description = "flake for jgrtp";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
    };
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-24.05";
    };
  };

  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations = {
      jgrtp = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./laptop-configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
  };
}

