{ config, pkgs, ... }:

{
  # TODO: This shouldn't be in common
  #boot = {
  #  loader = {
  #    systemd-boot.enable = true;
  #    efi.canTouchEfiVariables = true;
  #  };
  #};

  environment = {
    systemPackages = with pkgs; [
      docker
      docker-compose
      fastfetch
      git
      htop
      neovim
      nixfmt-classic
      python310Full
      rsync
      tmux
      unzip
      vim
      wget
    ];
    variables = {
      EDITOR = "vim";
      GIT_EDITOR = "vim";
    };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = { config = { allowUnfree = true; }; };

  programs = {
    ssh = { startAgent = true; };
    zsh = {
      enable = true;
      interactiveShellInit = ''
        export GIT_EDITOR="`which vim`"
        export EDITOR="`which vim`"
      '';
    };
  };

  services = {
    # Tailscale mesh network
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };
  };

  time = { timeZone = "America/Vancouver"; };

  users = {
    users = {
      jamesgray = with pkgs; {
        description = "James Gray";
        extraGroups = [ "docker" "networkmanager" "wheel" ];
        isNormalUser = true;
        shell = zsh;
      };
    };
  };

  virtualisation = { docker = { enable = true; }; };
}
