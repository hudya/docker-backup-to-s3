#!/bin/bash

test -z $DEBUG || set -x



dateISO() {
  date -u  +"%Y-%m-%dT%H:%M:%SZ"
}


runbackup() {
  started=$(date +%s)
  startedAt=$(date -u -d @$started  +"%Y-%m-%dT%H:%M:%SZ")

  printf "{\"backup\":{\"state\":\"start\", \"startedAt\":\"%s\", \"message\":\"%s\"}}\n" "$startedAt" "Starting backup from: $DATA_PATH to $S3_PATH/$s3name"

  if [ "$PREFIX" ]; then
      name="$PREFIX-$startedAt.tgz"
  else
      name="$startedAt.tgz"
  fi
  s3name=$name.aes

  # run pre-backup command if specified
  if [ ! -z "$PRE_BACKUP_COMMAND" ]; then
    printf "{\"backup\":{\"state\":\"pre-backup\", \"startedAt\":\"%s\", \"message\":\"%s\"}}\n" "$(dateISO)" "Running pre-backup command: $PRE_BACKUP_COMMAND"
    pre_cmd_output="$(eval $PRE_BACKUP_COMMAND 2>&1)"
    printf "{\"backup\":{\"state\":\"pre-backup-command-run\", \"result\": \"%s\", \"exit-code\":\"%s\"}}\n" "$pre_cmd_output" "$?"
  fi

  tar czf /tmp/$name  -C $DATA_PATH .
  openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100100 -salt -k "${AES_PASSPHRASE}" -in /tmp/$name -out /tmp/$s3name

  output=$( aws s3 cp $PARAMS "/tmp/$s3name" "$S3_PATH/$s3name" 2>&1 )
  code=$?
  if [ $code ]; then
      result="success"
  else
      result="error:$code"
  fi

  rm -f /tmp/$name
  rm -f /tmp/$s3name

  finished=$(date +%s)
  duration=$(( finished - started ))

  printf "{\"backup\":{\"state\":\"%s\" \"startedAt\":\"%s\", \"duration\":\"%i seconds\", \"name\":\"%s/%s\", \"output\":\"%s\"}}\n"  "$result" "$startedAt" "$duration" "$S3_PATH" "$s3name" "$output"
}



(
  flock -n 200 || exit 1

  exec &> >( tee -a ${LOGFILE:-/var/log/backup.log} )
  # exec 2>&1 

  runbackup
) 200> /var/lock/backup

