{ config, pkgs, ... }:

{
  imports = [
    <home-manager/nixos>
    ./desktop-hardware-configuration.nix
    ./home.nix
    ./common.nix
  ];

  environment = {
    systemPackages = with pkgs; [
      openrgb-with-all-plugins
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
      xorg.xinit
      x11vnc
    ];
    shells = with pkgs; [
      zsh
    ];
  };

  boot = {
    loader = {
      #systemd-boot = { configurationLimit = 1; };
      efi = {
        efiSysMountPoint = "/boot";
        canTouchEfiVariables = true;
      };
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
        useOSProber = true;
      };
    };
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    pulseaudio = {
      enable = false;
    };
  };

  networking = {
    hostName = "jgrnix";
    hostId = "876f1ee1";
    firewall = {
      enable = true;
      allowPing = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = [ 22 3389 ];
      allowedUDPPorts = [ 22 3389 ];
    };
    interfaces = {
      wlo1 = { wakeOnLan = { enable = true; }; };
    };
    networkmanager = {
      enable = true;
      settings = {
        connection = {
          "ethernet.wake-on-lan" = "magic";
          "wifi.wake-on-wlan" = "magic";
        };
      };
    };
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
    hardware = {
      openrgb = { enable = true; };
    };
    printing = { enable = true; };
    tailscale = { enable = true; };
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        UseDns = false;
      };
    };

    xserver = {
      enable = true;
      displayManager = { lightdm = { enable = true; }; };
      xkb = {
        layout = "us";
        variant = "";
      };
    };

    xrdp = {
      enable = true;
      defaultWindowManager = "startplasma-x11";
      openFirewall = true;
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
