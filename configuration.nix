{ config, pkgs, lib, ... }:

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
      direnv
      ethtool
      exiftool
      ffmpeg
      google-authenticator
      immich-go
      killall
      lm_sensors
      meslo-lgs-nf
      netdata
      nginx
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
          Origins = "https://cockpit.jgray.me wss://cockpit.jgray.me";
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
      enable = true;

      config = {
        global = {
          # update interval
          "update every" = 15;
        };
        ml = { "enabled" = "no"; };
      };
    };

    nginx = {
      enable = true;
      sslDhparam = "/tank9000/ds1/nginx/certs/dhparams.pem";
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = let
        SSL = {
          forceSSL = true;
          sslCertificate = "/tank9000/ds1/nginx/certs/cert.pem";
          sslCertificateKey = "/tank9000/ds1/nginx/certs/key.pem";
        }; LETSENCRYPT_SSL = {
          forceSSL = true;
          sslCertificate = "/tank9000/ds1/nginx/certs/letsencrypt-cert.pem";
          sslCertificateKey = "/tank9000/ds1/nginx/certs/letsencrypt-key.pem";
        }; in {
          "adguard.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:3000"; });
          "jgray.me" = ( SSL // { locations."/".proxyPass = "http://127.0.0.1:380/"; });
          "dashy.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:28080"; });
          "www.jgray.me" = ( SSL // { locations."/".proxyPass = "http://127.0.0.1:380/"; });
          "actual.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:5006/"; });
          "bandcamp.jgray.me" = ( SSL // { locations."/".proxyPass = "http://127.0.0.1:4533/"; });
          "bb.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:8100/"; });
          "christmas.jgray.me" = ( SSL // { locations."/".proxyPass = "http://127.0.0.1:32768/"; });
          "cockpit.jgray.me" = ( LETSENCRYPT_SSL // {
            locations = {
              "/" = {
                proxyPass = "http://127.0.0.1:9090/";
                proxyWebsockets = true;
                extraConfig = ''
                  # Required to proxy the connection to Cockpit
                  proxy_set_header Host $host;
                  proxy_set_header X-Forwarded-Proto $scheme;

                  # Required for web sockets to function
                  proxy_buffering off;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection "upgrade";

                  # Pass ETag header from Cockpit to clients.
                  # See: https://github.com/cockpit-project/cockpit/issues/5239
                  gzip off;
                '';
              };
            };
          });
          "ersatztv.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://192.168.1.69:8409"; });
          "frigate.jgray.me" = ( LETSENCRYPT_SSL // {
            locations = {
              "/" = {
                proxyPass = "http://127.0.0.1:5000/";
                proxyWebsockets = true;
              };
            };
          });
          "hass.jgray.me" = ( SSL // {
            locations = {
              "/" = {
                proxyPass = "http://127.0.0.1:8123/";
                proxyWebsockets = true;
                extraConfig = ''
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection "upgrade";
                '';
              };
            };
          });
          "immich.jgray.me" = ( SSL // {
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString config.services.immich.port}/";
              proxyWebsockets = true;
              recommendedProxySettings = true;
              extraConfig = ''
                client_max_body_size 50000M;
                proxy_read_timeout   600s;
                proxy_send_timeout   600s;
                send_timeout         600s;
              '';
            };
          });
          "ipod.jgray.me" = ( SSL // { locations."/".proxyPass = "http://127.0.0.1:14533/"; });
          "jellyfin.jgray.me" = ( SSL // {
            extraConfig = ''
              if ($scheme = "http") {
                  return 301 https://$host$request_uri;
              }

              ## The default `client_max_body_size` is 1M, this might not be enough for some posters, etc.
              client_max_body_size 20M;

              ssl_session_timeout 1d;
              ssl_session_cache shared:MozSSL:10m; # about 40000 sessions
              ssl_session_tickets off;

              ssl_protocols TLSv1.2 TLSv1.3;
              ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
              ssl_prefer_server_ciphers on;
              set $jellyfin 127.0.0.1;

              add_header Strict-Transport-Security "max-age=3153600" always;
              #add_header X-Frame-Options "SAMEORIGIN";
              #add_header X-XSS-Protection "0"; # Do NOT enable. This is obsolete/dangerous
              #add_header X-Content-Type-Options "nosniff";

              add_header Cross-Origin-Opener-Policy "same-origin" always;
              add_header Cross-Origin-Embedder-Policy "require-corp" always;
              add_header Cross-Origin-Resource-Policy "same-origin" always;

              location / {
                  proxy_pass http://$jellyfin:8096;

                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                  proxy_set_header X-Forwarded-Protocol $scheme;
                  proxy_set_header X-Forwarded-Host $http_host;

                  # Disable buffering when the nginx proxy gets very resource heavy upon streaming
                  proxy_buffering off;
              }

              location = /web/ {
                  # Proxy main Jellyfin traffic
                  proxy_pass http://$jellyfin:8096/web/index.html;
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                  proxy_set_header X-Forwarded-Protocol $scheme;
                  proxy_set_header X-Forwarded-Host $http_host;
              }

              location /socket {
                  # Proxy Jellyfin Websockets traffic
                  proxy_pass http://$jellyfin:8096;
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection "upgrade";
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                  proxy_set_header X-Forwarded-Protocol $scheme;
                  proxy_set_header X-Forwarded-Host $http_host;
              }
            '';
          });
          "lubelogger.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:48080/"; });
          "mealie.jgray.me" = ( SSL // { locations."/".proxyPass = "http://127.0.0.1:9925/"; });
          "miniflux.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:280/"; });
          "music.jgray.me" = ( SSL // { locations."/".proxyPass = "http://127.0.0.1:24533/"; });
          "nextcloud.jgray.me" = ( SSL // {
            extraConfig = ''
              if ($scheme = "http") {
                  return 301 https://$host$request_uri;
              }

              location / {
                  proxy_pass http://127.0.0.1:11000$request_uri;

                  proxy_buffering off;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Port $server_port;
                  proxy_set_header X-Forwarded-Scheme $scheme;
                  proxy_set_header X-Forwarded-Proto $scheme;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header Accept-Encoding "";
                  proxy_set_header Host $host;

                  client_body_buffer_size 512k;
                  proxy_read_timeout 86400s;
                  client_max_body_size 0;

                  # Websocket
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection $connection_upgrade;
              }

              # Make a regex exception for `/.well-known` so that clients can still
              # access it despite the existence of the regex rule
              # `location ~ /(\.|autotest|...)` which would otherwise handle requests
              # for `/.well-known`.
              location ^~ /.well-known {
                  # The rules in this block are an adaptation of the rules
                  # in `.htaccess` that concern `/.well-known`.

                  location = /.well-known/carddav { return 301 /remote.php/dav/; }
                  location = /.well-known/caldav  { return 301 /remote.php/dav/; }

                  location /.well-known/acme-challenge    { try_files $uri $uri/ =404; }
                  location /.well-known/pki-validation    { try_files $uri $uri/ =404; }

                  # Let Nextcloud's API for `/.well-known` URIs handle all other
                  # requests by passing them to the front-end controller.
                  return 301 /index.php$request_uri;
              }

              ssl_session_timeout 1d;
              ssl_session_cache shared:MozSSL:10m; # about 40000 sessions
              ssl_session_tickets off;

              ssl_protocols TLSv1.2 TLSv1.3;
              ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
              ssl_prefer_server_ciphers on;
            '';
          });
          "oi.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:11111/"; });
          "vw.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:180/"; });
          "swos.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://192.168.1.2/"; });
          "mqtt.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:58080"; });
          "cups.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://192.168.1.57:631"; });
          "sonarr.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:8989"; });
          "radarr.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:7878"; });
          "lidarr.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:8686"; });
          "sabnzbd.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:7979"; });
          "sabnzbdmusic.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:7777"; });
          "musicassistant.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:8095"; });
          "netdata.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:19999"; });
          "scrutiny.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:38080"; });
          "uptimekuma.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:3001"; });
          "portainer.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:9000"; });
          "unifi.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://192.168.1.1"; });
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
          OLLAMA_API_BASE_URL = "http://192.168.1.219:11434";
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
      allowedTCPPorts = [ 22 2049 137 138 139 445 80 443 1883 8095 8008 8009 631 ];
      allowedUDPPorts =
        [ 22 2049 137 138 139 445 config.services.tailscale.port 1900 5350 5351 5353 8095 8097 631 ];
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
      bandcamp = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./bandcamp/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./bandcamp/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      bb = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./bb/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./bb/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      christmas-community = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./christmas-community/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./christmas-community/docker-compose.yml
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
      ersatztv = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./ersatztv/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./ersatztv/docker-compose.yml
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
      homeassistant = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./hass/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./hass/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      "immich-server" = {
        serviceConfig = {
          PrivateDevices = lib.mkForce false;
        };
      };
      ipod = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./ipod/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./ipod/docker-compose.yml
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
      lidarr = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./lidarr/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./lidarr/docker-compose.yml
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
      mass = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./mass/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./mass/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
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
      miniflux = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./miniflux/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./miniflux/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      music = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./navidrome/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./navidrome/docker-compose.yml
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
      portainer = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./portainer/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./portainer/docker-compose.yml
            } stop
          '';
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
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
      radarr = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./radarr/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./radarr/docker-compose.yml
            } stop
          '';
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      sabnzbd = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./sabnzbd/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./sabnzbd/docker-compose.yml
            } stop
          '';
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      sabnzbdmusic = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./sabnzbdmusic/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./sabnzbdmusic/docker-compose.yml
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
      sonarr = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./sonarr/docker-compose.yml
            } up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./sonarr/docker-compose.yml
            } stop
          '';
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
      watchtower = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./watchtower/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./watchtower/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      wordpress = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./wordpress/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./wordpress/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      zigbee2mqtt = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./z2mqtt/docker-compose.yml
            } up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${
              ./z2mqtt/docker-compose.yml
            } stop
          '';
          RemainAfterExit = true;
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
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
