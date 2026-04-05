{ config, pkgs, lib, ... }:

let
  # Import docker-compose service helpers
  dockerComposeHelpers = import ./modules/docker-compose-service.nix { inherit pkgs lib; };
  inherit (dockerComposeHelpers) mkDockerComposeService mkDockerComposeServiceDetached mkDockerComposeServiceOneshot;
in

{
  imports = [
    # Include the results of the hardware scan.
    ./server-hardware-configuration.nix
    # Include Home Manager configuration
    <home-manager/nixos>
    # Secrets management
    <agenix/modules/age.nix>
    # Custom modules
    ./home.nix
    ./common.nix
    ./modules/nginx.nix
  ];

  # Boot configuration
  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;
      extraPools = [ "tank9000" "backup9000" ];
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems = {
    "/media/immich/archive" = {
      device = "/tank9000/ds1/nextcloud/admin/files/Photos";
      options = [ "bind" "nofail" ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      (pkgs.callPackage <agenix/pkgs/agenix.nix> { }) # Agenix CLI
      beep
      cockpit
      claude-code
      ethtool
      exiftool
      ffmpeg
      google-authenticator
      immich-go
      killall
      lm_sensors
      liquidsoap
      meslo-lgs-nf
      netdata
      nginx
      nodejs_24
      rclone
      sanoid
      smartmontools
      speedtest-cli
      sqlite
      zfs-prune-snapshots
    ];
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };

  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
        intel-vaapi-driver # For older processors. LIBVA_DRIVER_NAME=i965
      ];
    };
  };

  age = {
    secrets = {
      "backup-b2-env" = { file = ./secrets/backup-b2-env.age; };
      "bb-env" = { file = ./secrets/bb-env.age; };
      "bandcamp-env" = { file = ./secrets/bandcamp-env.age; };
      "frigate-env" = { file = ./secrets/frigate-env.age; };
      "ipod-env" = { file = ./secrets/ipod-env.age; };
      "lubelogger-env" = { file = ./secrets/lubelogger-env.age; };
      "mealie-env" = { file = ./secrets/mealie-env.age; };
      "miniflux-db-env" = { file = ./secrets/miniflux-db-env.age; };
      "miniflux-env" = { file = ./secrets/miniflux-env.age; };
      "music-env" = { file = ./secrets/music-env.age; };
      "vw-env" = { file = ./secrets/vw-env.age; };
      "wordpress-env" = { file = ./secrets/wordpress-env.age; };
      "scrutiny-config" = { file = ./secrets/scrutiny-config.age; };
      "radio-env" = { file = ./secrets/radio-env.age; };
    };
  };

  # Service configuration
  services = {
    adguardhome = {
      enable = true;
      openFirewall = true;
      settings = {
        dns = {
          upstream_dns = [
            "https://dns10.quad9.net/dns-query"
          ];
        };
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
          parental_enabled = false;  # Parental control-based DNS requests filtering.
          safe_search = {
            enabled = false;  # Enforcing "Safe search" option for search engines, when possible.
          };
        };
        # The following notation uses map
        # to not have to manually create {enabled = true; url = "";} for every filter
        # This is, however, fully optional
        filters = map(url: { enabled = true; url = url; }) [
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt"  # The Big List of Hacked Malware Web Sites
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt"  # malicious url blocklist
        ];
      };
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        userServices = true;
      };
      extraServiceFiles = {
        smb = ''
          <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
           <name replace-wildcards="yes">%h</name>
           <service>
            <type>_adisk._tcp</type>
            <txt-record>sys=waMa=0,adVF=0x100</txt-record>
            <txt-record>dk0=adVN=Time Capsule,adVF=0x82</txt-record>
           </service>
           <service>
            <type>_smb._tcp</type>
            <port>445</port>
           </service>
          </service-group>
        '';
      };
    };
    cockpit = {
      enable = true;
      openFirewall = true;
      port = 9090;
      settings = {
        WebService = {
          AllowUnencrypted = false;
          Origins = lib.mkForce "https://cockpit.jgray.me wss://cockpit.jgray.me";
          ProtocolHeader = "X-Forwarded-Proto";
        };
      };
    };
    hardware = { openrgb.enable = true; };

    mosquitto = {
      enable = true;
      listeners = [
        {
          acl = [ "pattern readwrite #" ];
          omitPasswordAuth = true;
          settings = {
            allow_anonymous = true;
          };
        }
      ];
    };

    immich = {
      enable = true;
      host = "0.0.0.0";
      mediaLocation = "/tank9000/ds1/immich";
    };

    netdata = {
      enable = false;

      config = {
        global = {
          # update interval
          "update every" = 15;
        };
        ml = { "enabled" = "no"; };
      };
    };


    # Note that to enable macos mounts of ZFS datasets over NFS within a Tailscale tailnet, must set as follows (e.g. for dataset tank9000/example):
    # $ sudo zfs set sharenfs="rw=100.0.0.0/8,all_squash,anonuid=1000,anongid=100,insecure" tank9000/example
    # This enables hosts on the tailnet to mount the share r/w, and files created will be owned by jamesgray:users.
    # TODO: See about reassigning client ips to tighten up the tailnet subnet mask
    nfs.server = { enable = true; };

    open-webui = {
      enable = true;
      openFirewall = true;
      host = "0.0.0.0";
      port = 11111;
      environment =
        {
          OLLAMA_API_BASE_URL = "http://192.168.1.156:11434";
          ENABLE_WEBSOCKET_SUPPORT = "false";
        }
      ;
    };

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        UseDns = false;
      };
    };

    printing = {
      enable = true;
      drivers = [ pkgs.brlaser ];
      openFirewall = true;
      allowFrom = [ "all" ];
      browsing = true;
      defaultShared = true;
      browsedConf = ''
        BrowseDNSSDSubTypes _cups,_print
        BrowseLocalProtocols all
        BrowseRemoteProtocols all
        CreateIPPPrinterQueues All
        BrowseProtocols all
      '';
      listenAddresses = [ "*:631" ];
      extraConf = ''
        DefaultAuthType Basic
        DefaultEncryption IfRequested
        ServerAlias *
      '';
    };

    samba = {
      enable = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "security" = "user";
          "server string" = "smbnix";
          "netbios name" = "smbnix";
          "server role" = "standalone server";
          "dns proxy" = "no";
          "ea support" = "yes";

          "pam password change" = "yes";
          "map to guest" = "bad user";
          "usershare allow guests" = "yes";
          "create mask" = "0664";
          "force create mode" = "0664";
          "directory mask" = "0775";
          "force directory mode" = "0775";
          "follow symlinks" = "yes";
          "load printers" = "no";
          "printing" = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";
          "strict locking" = "no";
          "aio read size" = "0";
          "aio write size" = "0";
          "vfs objects" = "acl_xattr catia fruit streams_xattr";
          "inherit permissions" = "yes";

          # Security
          "client ipc max protocol" = "SMB3";
          "client ipc min protocol" = "SMB2";
          "client max protocol" = "SMB3";
          "client min protocol" = "SMB2";
          "server max protocol" = "SMB3";
          "server min protocol" = "SMB2";

          # Time Machine
          "fruit:aapl" = "yes";
          "fruit:delete_empty_adfiles" = "yes";
          "fruit:metadata" = "stream";
          "fruit:model" = "MacSamba";
          "fruit:nfs_aces" = "no";
          "fruit:posix_rename" = "yes";
          "fruit:time machine" = "yes";
          "fruit:veto_appledouble" = "no";
          "fruit:wipe_intentionally_left_blank_rfork" = "yes";
          "spotlight" = "no";
        };
        "share" = {
          path = "/tank9000/ds1/share";
          browseable = "yes";
          "read only" = "no";
          "writeable" = "yes";
          "inherit acls" = "yes";

          "write list" = "james.gray";
          "create mask" = "0644";
          "directory mask" = "0755";
          "case sensitive" = "true";
          "default case" = "lower";
          "preserve case" = "yes";
          "short preserve case" = "yes";

          "force user" = "james.gray";
          "valid users" = "james.gray";
        };
        "navidrome" = {
          path = "/tank9000/ds1/navidrome";

          browseable = "yes";
          "read only" = "no";
          "writeable" = "yes";
          "inherit acls" = "yes";

          "write list" = "james.gray";
          "create mask" = "0644";
          "directory mask" = "0755";
          "case sensitive" = "true";
          "default case" = "lower";
          "preserve case" = "yes";
          "short preserve case" = "yes";

          "force user" = "james.gray";
          "valid users" = "james.gray";
        };
        "jellyfin" = {
          path = "/tank9000/ds1/jellyfin";

          browseable = "yes";
          "read only" = "no";
          "writeable" = "yes";
          "inherit acls" = "yes";

          "write list" = "james.gray";
          "create mask" = "0644";
          "directory mask" = "0755";
          "case sensitive" = "true";
          "default case" = "lower";
          "preserve case" = "yes";
          "short preserve case" = "yes";

          "force user" = "james.gray";
          "valid users" = "james.gray";
        };
        "Time Capsule" = {
          path = "/tank9000/timemachine";
          browseable = "yes";
          "read only" = "no";
          "inherit acls" = "yes";

          "fruit:time machine" = "yes";
          "fruit:time machine max size" = "512G";
          "write list" = "timemachine";
          "create mask" = "0600";
          "directory mask" = "0700";
          "case sensitive" = "true";
          "default case" = "lower";
          "preserve case" = "yes";
          "short preserve case" = "yes";

          "force user" = "timemachine";
          "valid users" = "timemachine";
        };
      };
    };

    # Sanoid ZFS dataset snapshotting
    sanoid = {
      enable = true;
      datasets.tank9000 = {
        autoprune = true;
        autosnap = true;
        recursive = true;
        hourly = 24;
        daily = 7;
      };
    };

    # Syncoid ZFS dataset replication
    syncoid = {
      enable = true;
      user = "syncoid";
      localSourceAllow = [
        "compression"
        "create"
        "mount"
        "mountpoint"
        "receive"
        "rollback"
        "bookmark"
        "hold"
        "send"
        "snapshot"
        "destroy"
      ];
      localTargetAllow = [
        "compression"
        "create"
        "mount"
        "mountpoint"
        "receive"
        "rollback"
        "bookmark"
        "hold"
        "send"
        "snapshot"
        "destroy"
      ];
      commonArgs = [ "--no-privilege-elevation" "--recursive" "--no-sync-snap" "--skip-parent" ];
      commands."tank9000" = {
        source = "tank9000/ds1";
        target = "backup9000/ds1";
      };
      commands."timemachine" = {
        source = "tank9000/timemachine";
        target = "backup9000/timemachine";
      };
    };

    zfs = { autoScrub.enable = true; };
  };

  networking = {
    hostName = "hal9000";
    hostId = "16cff501";
    firewall = {
      enable = true;
      allowPing = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = [ 22 2049 137 138 139 445 80 443 1883 8095 8008 8009 631 53 ];
      allowedUDPPorts =
        [ 22 2049 137 138 139 445 config.services.tailscale.port 1900 5350 5351 5353 8095 8097 631 53 ];
    };
    interfaces = {
      wlo1 = { wakeOnLan = { enable = true; }; };
      eno2 = { wakeOnLan = { enable = true; }; };
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

  systemd = {
    services = {
      "NetworkManager-wait-online" = { enable = false; };
      actual = mkDockerComposeService "actual" ./actual/docker-compose.yml;
      bandcamp = mkDockerComposeServiceDetached "bandcamp" ./bandcamp/docker-compose.yml;
      bb = mkDockerComposeServiceDetached "bb" ./bb/docker-compose.yml;
      christmas-community = mkDockerComposeService "christmas-community" ./christmas-community/docker-compose.yml;
      dashy = mkDockerComposeService "dashy" ./dashy/docker-compose.yml;
      ersatztv = mkDockerComposeService "ersatztv" ./ersatztv/docker-compose.yml;
      frigate = mkDockerComposeServiceDetached "frigate" ./frigate/docker-compose.yml;
      homeassistant = mkDockerComposeServiceDetached "homeassistant" ./hass/docker-compose.yml;
      "immich-server" = {
        serviceConfig = {
          PrivateDevices = lib.mkForce false;
        };
      };
      ipod = mkDockerComposeServiceDetached "ipod" ./ipod/docker-compose.yml;
      jellyfin = mkDockerComposeService "jellyfin" ./jellyfin/docker-compose.yml;
      lidarr = mkDockerComposeService "lidarr" ./lidarr/docker-compose.yml;
      lubelogger = mkDockerComposeService "lubelogger" ./lubelogger/docker-compose.yml;
      mass = mkDockerComposeServiceDetached "mass" ./mass/docker-compose.yml;
      mealie = mkDockerComposeServiceDetached "mealie" ./mealie/docker-compose.yml;
      miniflux = mkDockerComposeServiceDetached "miniflux" ./miniflux/docker-compose.yml;
      music = mkDockerComposeServiceDetached "music" ./navidrome/docker-compose.yml;
      nextcloud = mkDockerComposeServiceOneshot "nextcloud" ./nextcloud/docker-compose.yml;
      nextcloud-backup = {
        serviceConfig = {
          User = "root";
          Group = "root";
          Type = "oneshot";
        };
        path = with pkgs; [ pkgs.rclone pkgs.docker ];
        script = ''
          /home/jamesgray/code/nix-config/nextcloud/backup-b2.sh
        '';
      };
      letsencrypt-copy-certs = {
        serviceConfig = {
          User = "root";
          Group = "root";
          Type = "oneshot";
        };
        path = with pkgs; [ pkgs.openssh ];
        script = ''
          /home/jamesgray/code/nix-config/letsencrypt/copy-certs.sh
        '';
      };
      portainer = mkDockerComposeService "portainer" ./portainer/docker-compose.yml;
      uptime-kuma = mkDockerComposeService "uptime-kuma" ./uptime-kuma/docker-compose.yml;
      radarr = mkDockerComposeService "radarr" ./radarr/docker-compose.yml;
      radio = mkDockerComposeServiceDetached "radio" ./liquidsoap/docker-compose.yml;
      sabnzbd = mkDockerComposeService "sabnzbd" ./sabnzbd/docker-compose.yml;
      sabnzbdmusic = mkDockerComposeService "sabnzbdmusic" ./sabnzbdmusic/docker-compose.yml;
      scrutiny-collector-metrics = {
        serviceConfig = {
          User = "root";
          Group = "root";
          Type = "oneshot";
        };
        path = with pkgs; [ pkgs.docker ];
        script = ''
          docker exec scrutiny /opt/scrutiny/bin/scrutiny-collector-metrics run
        '';
      };
      scrutiny = mkDockerComposeServiceDetached "scrutiny" ./scrutiny/docker-compose.yml;
      sonarr = mkDockerComposeService "sonarr" ./sonarr/docker-compose.yml;
      vaultwarden = mkDockerComposeServiceDetached "vaultwarden" ./vaultwarden/docker-compose.yml;
      vaultwarden-backup = {
        enable = true;
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          Group = "root";
        };
        path = with pkgs; [ pkgs.sqlite ];
        script = ''
          DATE=$(date '+%Y%m%d-%H%M')
          sqlite3 /tank9000/ds1/vaultwarden/data/db.sqlite3 ".backup '/tank9000/ds1/nextcloud/admin/files/Backup/vaultwarden/db-$DATE.sqlite3'"
          chown -R www-data:www-data /tank9000/ds1/nextcloud/admin/files/Backup/vaultwarden/db-$DATE.sqlite3
        '';
      };
      watchtower = mkDockerComposeServiceDetached "watchtower" ./watchtower/docker-compose.yml;
      wordpress = mkDockerComposeServiceDetached "wordpress" ./wordpress/docker-compose.yml;
      zigbee2mqtt = mkDockerComposeServiceDetached "zigbee2mqtt" ./z2mqtt/docker-compose.yml;
      zfs-prune-snapshots = {
        serviceConfig = {
          User = "root";
          Group = "root";
          Type = "oneshot";
        };
        path = with pkgs; [ pkgs.openssh ];
        script = "zfs-prune-snapshots 1w";
      };
    };
    # Disable sleep! Servers can sleep when they're dead!
    sleep = {
      extraConfig = ''
        AllowSuspend=no
        AllowHibernation=no
        AllowHybridSleep=no
        AllowSuspendThenHibernate=no
      '';
    };
    timers = {
      letsencrypt-copy-certs = {
        wantedBy = [ "timers.target" ];
        partOf = [ "letsencrypt-copy-certs.service" ];
        timerConfig = {
          OnCalendar = "*-*-* 02:00:00";
          Unit = "letsencrypt-copy-certs.service";
        };
      };
      nextcloud-backup = {
        wantedBy = [ "timers.target" ];
        partOf = [ "nextcloud-backup.service" ];
        timerConfig = {
          OnCalendar = "*-*-* 02:00:00";
          Unit = "nextcloud-backup.service";
        };
      };
      nextcloud-jellyfin-sync = {
        wantedBy = [ "timers.target" ];
        partOf = [ "nextcloud-jellyfin-sync.service" ];
        timerConfig = {
          OnCalendar = "*:0/15";
          Unit = "nextcloud-jellyfin-sync.service";
        };
      };
      scrutiny-collector-metrics = {
        wantedBy = [ "timers.target" ];
        partOf = [ "scrutiny-collector-metrics.service" ];
        timerConfig = {
          OnCalendar = "*:0/15";
          Unit = "scrutiny-collector-metrics.service";
        };
      };
      vaultwarden-backup = {
        wantedBy = [ "timers.target" ];
        partOf = [ "vaultwarden-backup.service" ];
        timerConfig = {
          OnCalendar = "daily";
          Unit = "vaultwarden-backup.service";
        };
      };
      zfs-prune-snapshots = {
        wantedBy = [ "timers.target" ];
        partOf = [ "zfs-prune-snapshots.service" ];
        timerConfig = {
          OnCalendar = "Sun *-*-* 03:00:00";
          Unit = "zfs-prune-snapshots.service";
        };
      };
    };
  };

  users = {
    motd = "I'm sorry, Dave, I'm afraid I can't do that.";
    users = {
      homeassistant = with pkgs; {
        description = "home assistant user";
        isSystemUser = true;
        group = "homeassistant";
        uid = 998;
      };
      "james.gray" = with pkgs; {
        description = "James Gray (macos)";
        extraGroups = [ "macos" ];
        isNormalUser = true;
        group = "james.gray";
        shell = bash;
      };
      syncoid = with pkgs; {
        description = "Syncoid User";
        extraGroups = [ "wheel" ];
        group = "syncoid";
        isSystemUser = true;
        shell = bash;
      };
      timemachine = with pkgs; {
        description = "Time Machine user";
        group = "timemachine";
        isNormalUser = true;
        shell = bash;
      };
      www-data = with pkgs; {
        description = "www-data";
        group = "www-data";
        isSystemUser = true;
        uid = 33;
      };
      immich = with pkgs; {
        description = "immich";
        group = "immich";
        uid = 986;
        extraGroups = [ "www-data" "video" "render" ];
      };
    };
    groups = {
      homeassistant = { gid = 994; };
      syncoid = { };
      timemachine = { };
      "james.gray" = { };
      macos = { gid = 1005; };
      www-data = { gid = 33; };
      immich = { gid = 980; };
    };
  };

  security = {
    pam = {
      services = {
        cockpit = {
          startSession = true;
          googleAuthenticator = {
            enable = true;
          };
        };
      };
    };
  };

  virtualisation = {
    docker = {
      storageDriver = "btrfs";
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
    oci-containers = {
      backend = "docker";
      containers = { };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
