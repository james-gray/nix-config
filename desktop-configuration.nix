{ config, pkgs, ... }:

{
  imports = [
    <home-manager/nixos>
    <agenix/modules/age.nix>
    ./desktop-hardware-configuration.nix
    ./home.nix
    ./common.nix
  ];

  environment = {
    systemPackages = with pkgs; [
      (pkgs.callPackage <agenix/pkgs/agenix.nix> { }) # Agenix CLI
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

  age = {
    secrets = {
      "wifi-password" = { file = ./secrets/wifi-password.age; };
    };
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
      allowedTCPPorts = [ 22 3389 3000 8080 11434 ];
      allowedUDPPorts = [ 22 3389 9 3000 8080 11434 ];
    };
    interfaces = {
      enp14s0 = { wakeOnLan = { enable = true; }; };
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
    ollama = {
      enable = true;
      host = "0.0.0.0";
      openFirewall = true;
      acceleration = "rocm";
      environmentVariables = {
        HCC_AMDGPU_TARGET = "gfx1101";
        OLLAMA_HOST = "0.0.0.0";
        OLLAMA_ORIGINS = "*";
      };
      rocmOverrideGfx = "11.0.1";
      loadModels = [ "mistral:7b" "deepseek-r1:14b" "llama3.1:8b" ];
    };
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

  systemd = {
    sleep = {
      extraConfig = ''
        AllowSuspend=no
        AllowHibernation=no
        AllowHybridSleep=no
        AllowSuspendThenHibernate=no
      '';
    };

    services = {
      NetworkManager-wait-online = {
        enable = false;
      };
      open-webui = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./open-webui/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./open-webui/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
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
