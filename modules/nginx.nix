{ config, lib, ... }:

{
  services.nginx = {
    enable = true;
    sslDhparam = "/tank9000/ds1/nginx/certs/dhparams.pem";
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Upgrade connection header for websockets
    appendHttpConfig = ''
      map $http_upgrade $connection_upgrade {
        default upgrade;
        ''' close;
      }
    '';

    virtualHosts = let
      SSL = {
        forceSSL = true;
        sslCertificate = "/tank9000/ds1/nginx/certs/cert.pem";
        sslCertificateKey = "/tank9000/ds1/nginx/certs/key.pem";
      };
      LETSENCRYPT_SSL = {
        forceSSL = true;
        sslCertificate = "/tank9000/ds1/nginx/certs/letsencrypt-cert.pem";
        sslCertificateKey = "/tank9000/ds1/nginx/certs/letsencrypt-key.pem";
      };
    in {
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

            # Required for web sockets to function
            proxy_buffering off;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

          '';
        };
      });

      "immich-local.jgray.me" = ( LETSENCRYPT_SSL // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.immich.port}/";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            client_max_body_size 50000M;
            proxy_read_timeout   600s;
            proxy_send_timeout   600s;
            send_timeout         600s;

            # Required for web sockets to function
            proxy_buffering off;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

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

      "oi.jgray.me" = ( LETSENCRYPT_SSL // {
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:11111/";
            proxyWebsockets = true;
            extraConfig = ''
              # Required for web sockets to function
              proxy_buffering off;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';
          };
        };
      });

      "vw.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:180/"; });
      "swos.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://192.168.1.2/"; });

      "mqtt.jgray.me" = ( LETSENCRYPT_SSL // {
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:58080";
          };
          "/api" = {
            proxyPass = "http://127.0.0.1:58080/api";
            proxyWebsockets = true;
            extraConfig = ''
              # Required for web sockets to function
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';
          };
        };
      });

      "cups.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:631"; });
      "sonarr.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:8989"; });
      "radarr.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:7878"; });
      "radio.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:18000/music"; });
      "radio-ipod.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:18000/ipod"; });
      "radio-bandcamp.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:18000/bandcamp"; });
      "lidarr.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:8686"; });
      "sabnzbd.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:7979"; });
      "sabnzbdmusic.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:7777"; });
      "musicassistant.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:8095"; });
      #"netdata.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:19999"; });
      "scrutiny.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:38080"; });
      "uptimekuma.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:3001"; });
      "portainer.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://127.0.0.1:9000"; });
      "unifi.jgray.me" = ( LETSENCRYPT_SSL // { locations."/".proxyPass = "http://192.168.1.1"; });
    };
  };
}
