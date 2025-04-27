{ config, pkgs, ... }:

{
  imports = [
    <home-manager/nixos>
    ./desktop-hardware-configuration.nix
    ./home.nix
    ./common.nix
  ];

  environment = { systemPackages = with pkgs; [
    audacity
    direnv
    feishin
    firefox
    gcc
    gimp
    hexdino
    jetbrains.idea-community
    kcalc
    libreoffice
    meslo-lgs-nf
    reaper
    rustup
    steam
    spotify
    super-productivity
    unrar-wrapper
    vlc
    wirelesstools
  ]; };

  boot = {
    loader = {
      systemd-boot = { configurationLimit = 1; };
      efi = { efiSysMountPoint = "/boot"; };
    };
  };

  hardware = { pulseaudio = { enable = false; }; };

  networking = {
    hostName = "jgrtp";
    hostId = "876f1ee1";
    networkmanager = { enable = true; };
  };

  nix = {
    package = pkgs.nixVersions.stable;
  };

  nixpkgs = {
    config = {
      packageOverrides = pkgs: {
        nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
          inherit pkgs;
        };
      };
    };
  };

  programs = {
    steam = {
      enable = true;
    };
    zsh = {
      enable = true;
    };
  };

  security = { rtkit = { enable = true; }; };

  services = {
    desktopManager = { plasma6 = { enable = true; }; };
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse = { enable = true; };
    };
    printing = { enable = true; };
    tailscale = { enable = true; };
    xserver = {
      enable = true;
      displayManager = { lightdm = { enable = true; }; };
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
