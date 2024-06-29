{ config, pkgs, ... }:

{
  imports = [
    ./laptop-hardware-configuration.nix
    <home-manager/nixos>
    ./home.nix
    ./common.nix
  ];

  environment = {
    systemPackages = with pkgs; [
      firefox
      meslo-lgs-nf
    ];
  };

  boot = {
    loader = {
      systemd-boot = {
        configurationLimit = 1;
      };
      efi = {
        efiSysMountPoint = "/boot";
      };
    };
  };

  hardware = {
    pulseaudio = {
      enable = false;
    };
  };

  networking = {
    hostName = "jgrtp";
    hostId = "876f1ee1";
    networkmanager = {
      enable = true;
    };
  };

  security = {
    rtkit = {
      enable = true;
    };
  };

  services = {
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse = {
        enable = true;
      };
    };
    printing = {
      enable = true;
    };
    xserver = {
      enable = true;
      desktopManager = {
        cinnamon = {
          enable = true;
        };
      };
      displayManager = {
        lightdm = {
          enable = true;
        };
      };
      layout = "us";
      xkbVariant = "";
    };
  };

  sound = {
    enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
