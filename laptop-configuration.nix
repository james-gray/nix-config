{ config, pkgs, ... }:

{
  imports = [
    ./laptop-hardware-configuration.nix
    ./home.nix
    ./common.nix
  ];

  environment = { systemPackages = with pkgs; [
    audacity
    firefox
    fprintd
    gimp
    jetbrains.idea-community
    libreoffice
    meslo-lgs-nf
    reaper
    steam
    super-productivity
    vlc
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
    package = pkgs.nixFlakes;
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
  };

  security = { rtkit = { enable = true; }; };

  services = {
    desktopManager = { plasma6 = { enable = true; }; };
    fprintd = {
      enable = true;
    };
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse = { enable = true; };
    };
    printing = { enable = true; };
    xserver = {
      enable = true;
      displayManager = { lightdm = { enable = true; }; };
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };

  sound = { enable = true; };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
