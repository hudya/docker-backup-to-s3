#!/bin/bash

set -e
test -z $DEBUG || set -x


: ${AWS_DEFAULT_REGION:?"AWS_DEFAULT_REGION env variable is required"}
: ${AWS_ACCESS_KEY_ID:?"AWS_ACCESS_KEY_ID env variable is required"}
: ${AWS_SECRET_ACCESS_KEY:?"AWS_SECRET_ACCESS_KEY env variable is required"}
: ${S3_PATH:?"S3_PATH env variable is required"}
: ${AES_PASSPHRASE:?"AES_PASSPHRASE env variable is required"}
export DATA_PATH=${DATA_PATH:-/data/}
CRON_SCHEDULE=${CRON_SCHEDULE:-3 5 * * *}

case $1 in 

  backup-once)
    exec /app/backup.sh
    ;;

  schedule)
    echo "Scheduling backup cron: $CRON_SCHEDULE"
    CRONFILE='/etc/crontabs/backup'
    export LOGFILE='/var/log/backup.log'

    touch $LOGFILE

    # CRON_ENV="PARAMS='$PARAMS'\nDATA_PATH='$DATA_PATH'\nS3_PATH='$S3_PATH'\nPREFIX='$PREFIX'\nAES_PASSPHRASE='$AES_PASSPHRASE'"
    CRON_ENV="$(env)"
    echo -e "$CRON_ENV\n\n$CRON_SCHEDULE /app/backup.sh"  > $CRONFILE
    crontab $CRONFILE

    exec crond -f
    # exec tail -f $LOGFILE
    ;;

  restore)
    : ${VERSION:?"VERSION env variable is required"}
    exec /app/restore.sh
    ;;

  *)
    echo "Error: must specify operation, one of backup-once, schedule or restore"
    exec "$@"
esac
