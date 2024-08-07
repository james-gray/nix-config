{ config, pkgs, ... }:

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
  ];

  # Boot configuration
  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;
      extraPools = [ "tank9000" "backup9000" ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      (pkgs.callPackage <agenix/pkgs/agenix.nix> { }) # Agenix CLI
      beep
      cockpit
      ethtool
      exiftool
      ffmpeg
      lm_sensors
      netdata
      rclone
      sanoid
      smartmontools
      sqlite
      zfs-prune-snapshots
    ];
  };

  age = {
    secrets = {
      "lubelogger-env" = { file = ./secrets/lubelogger-env.age; };
      "mealie-env" = { file = ./secrets/mealie-env.age; };
      "vw-env" = { file = ./secrets/vw-env.age; };
      "backup-b2-env" = { file = ./secrets/backup-b2-env.age; };
      "immich-env" = { file = ./secrets/immich-env.age; };
      "frigate-env" = { file = ./secrets/frigate-env.age; };
    };
  };

  # Service configuration
  services = {
    avahi = {
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
      port = 9090;
      settings = { WebService = { AllowUnencrypted = true; }; };
    };
    hardware = { openrgb.enable = true; };

    netdata = {
      enable = true;

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

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        UseDns = false;
      };
    };

    samba = {
      enable = true;
      securityType = "user";
      extraConfig = ''
        workgroup = WORKGROUP
        server string = smbnix
        netbios name = smbnix
        server role = standalone server
        dns proxy = no
        ea support = yes

        pam password change = yes
        map to guest = bad user
        usershare allow guests = yes
        create mask = 0664
        force create mode = 0664
        directory mask = 0775
        force directory mode = 0775
        follow symlinks = yes
        load printers = no
        printing = bsd
        printcap name = /dev/null
        disable spoolss = yes
        strict locking = no
        aio read size = 0
        aio write size = 0
        vfs objects = acl_xattr catia fruit streams_xattr
        inherit permissions = yes

        # Security
        client ipc max protocol = SMB3
        client ipc min protocol = SMB2
        client max protocol = SMB3
        client min protocol = SMB2
        server max protocol = SMB3
        server min protocol = SMB2

        # Time Machine
        fruit:aapl = yes
        fruit:delete_empty_adfiles = yes
        fruit:metadata = stream
        fruit:model = MacSamba
        fruit:nfs_aces = no
        fruit:posix_rename = yes
        fruit:time machine = yes
        fruit:veto_appledouble = no
        fruit:wipe_intentionally_left_blank_rfork = yes
        spotlight = no
      '';
      shares = {
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
        daily = 30;
        monthly = 3;
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
      commonArgs = [ "--no-privilege-elevation" "--recursive" ];
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
      allowedTCPPorts = [ 22 2049 137 138 139 445 ];
      allowedUDPPorts =
        [ 22 2049 137 138 139 445 config.services.tailscale.port ];
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
      actual = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./actual/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./actual/docker-compose.yml
            } stop
          '';
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      dashy = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./dashy/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./dashy/docker-compose.yml
            } stop
          '';
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      frigate = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./frigate/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./frigate/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      immich = {
        enable = false;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose --env-file /run/agenix/immich-env -f ${
              ./immich/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./immich/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      jellyfin = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./jellyfin/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./jellyfin/docker-compose.yml
            } stop
          '';
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      lubelogger = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./lubelogger/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./lubelogger/docker-compose.yml
            } stop
          '';
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      mealie = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./mealie/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./mealie/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      nextcloud = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./nextcloud/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./nextcloud/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
          Type = "oneshot";
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
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
      nextcloud-jellyfin-sync = {
        serviceConfig = {
          User = "root";
          Group = "root";
          Type = "oneshot";
        };
        path = with pkgs; [ pkgs.rsync ];
        script = ''
          rsync -r -c --progress --chown=jamesgray:users "/tank9000/ds1/nextcloud/admin/files/Family Home Videos/" "/tank9000/ds1/jellyfin/media/Family Home Videos"
          rsync -r -c --progress --chown=jamesgray:users "/tank9000/ds1/nextcloud/admin/files/Music/Bandcamp/" "/tank9000/ds1/jellyfin/media/Bandcamp"
        '';
      };
      uptime-kuma = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./uptime-kuma/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./uptime-kuma/docker-compose.yml
            } stop
          '';
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
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
      scrutiny = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./scrutiny/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./scrutiny/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      vaultwarden = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./vaultwarden/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./vaultwarden/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
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
    };
  };

  users = {
    motd = "I'm sorry, Dave, I'm afraid I can't do that.";
    users = {
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
    };
    groups = {
      syncoid = { };
      timemachine = { };
      "james.gray" = { };
      macos = { gid = 1005; };
      www-data = { gid = 33; };
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
