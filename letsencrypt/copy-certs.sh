scp root@192.168.1.1:/data/unifi-core/config/unifi-core.crt /tank9000/ds1/nginx/certs/letsencrypt-cert.pem
scp root@192.168.1.1:/data/unifi-core/config/unifi-core.key /tank9000/ds1/nginx/certs/letsencrypt-key.pem
chown -R nginx:nginx /tank9000/ds1/nginx/certs/letsencrypt-cert.pem
chown -R nginx:nginx /tank9000/ds1/nginx/certs/letsencrypt-key.pem
