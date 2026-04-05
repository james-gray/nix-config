{ config, pkgs, ... }:

{
  # Setup home-manager user config
  home-manager = {
    users = {
      jamesgray = { pkgs, ... }: {
        imports = [ ./modules/home-manager/shell-config.nix ];

        home = {
          stateVersion = "24.11";
          packages = with pkgs; [ powertop direnv ];
        };
      };
    };
  };
}
