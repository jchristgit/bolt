#!/bin/ash

set -ex

apk add --no-cache postgresql-client


while true; do
    echo [i] Sleeping for $BACKUP_INTERVAL seconds.
    sleep $BACKUP_INTERVAL

    echo [i] Running backup.
    backup_name=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
    pg_dump -d bolt -U bolt --data-only -Fc -Z 9 > "/backups/$backup_name"
    echo [i] Done.
done
