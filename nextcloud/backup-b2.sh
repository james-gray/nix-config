#!/bin/sh

# NextCloud to BackBlaze B2 Backup Script
# Adapted from script by Autoize (autoize.com) - see https://gist.github.com/simulacra10/b4bf2443d5912ff27959d7290e4b24d9

# This script creates an incremental backup of your NextCloud instance at BackBlaze's off-site location.
# BackBlaze B2 is an object storage service that is much less expensive than using Amazon S3 for the same purpose, with similar versioning and lifecycle management features.
# Uploads are free, and storage costs only $0.005/GB/month compared to S3's $0.022/GB/month.

DATA_DIR='/tank9000/ds1/nextcloud'

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo 'Started'
date +'%a %b %e %H:%M:%S %Z %Y'

source /run/agenix/backup-b2-env
export RCLONE_CONFIG_B2_TYPE=$RCLONE_CONFIG_B2_TYPE
export RCLONE_CONFIG_B2_ACCOUNT=$RCLONE_CONFIG_B2_ACCOUNT
export RCLONE_CONFIG_B2_KEY=$RCLONE_CONFIG_B2_KEY
export RCLONE_FAST_LIST=1

# Put NextCloud into maintenance mode.
# This ensures consistency between the database and data directory.
docker exec -u www-data nextcloud-aio-nextcloud php occ maintenance:mode --on

# Dump database and backup to B2
docker exec $PGHOST pg_dump -c -U $PGUSER $PGDATABASE > /tmp/nextcloud.sql

rclone sync -Pvc --transfers 10 /tmp/nextcloud.sql B2:$NEXTCLOUD_B2_BUCKET/nextcloud-database/nextcloud.sql
rm /tmp/nextcloud.sql

# Sync data to B2 in place, then disable maintenance mode
# NextCloud will be unavailable during the sync. This will take a while if you added much data since your last backup.
rclone sync -Pvc --transfers 10 --exclude "*/cache/*" $DATA_DIR B2:$NEXTCLOUD_B2_BUCKET/nextcloud-data/

# Turn off maintenance mode
docker exec -u www-data nextcloud-aio-nextcloud php occ maintenance:mode --off

date +'%a %b %e %H:%M:%S %Z %Y'
echo 'Finished'
