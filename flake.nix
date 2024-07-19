{
  description = "flake for jgrtp";

  inputs = {
    home-manager = { url = "github:nix-community/home-manager/release-24.05"; };
    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-24.05"; };
    nixpkgs-23-11 = { url = "github:NixOS/nixpkgs/nixos-23.11"; };
    nixos-06cb-009a-fingerprint-sensor = {
      url = "github:ahbnr/nixos-06cb-009a-fingerprint-sensor";
      inputs = { nixpkgs-23-11 = { follows = "nixpkgs-23-11"; }; };
    };
  };

  outputs = { self, nixpkgs, nixpkgs-23-11, home-manager
    , nixos-06cb-009a-fingerprint-sensor }@attrs: {
      nixosConfigurations = {
        jgrtp = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = attrs;
          modules = [
            ./laptop-configuration.nix
            home-manager.nixosModules.home-manager
            nixos-06cb-009a-fingerprint-sensor.nixosModules.open-fprintd
            nixos-06cb-009a-fingerprint-sensor.nixosModules.python-validity
          ];
        };
      };
    };
}

