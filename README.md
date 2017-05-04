# hudya/backup-to-s3

Docker container that periodically backups files to Amazon S3 using awscli and cron.
All files will be tar:ed and encrypted with AES 256 CBC.

**Always test to restore the files from the backup, before relying on it.**


To decrypt resulting s3 object 2016-04-11T07:25:30Z.tgz.aes:
 
 ```
openssl aes-256-cbc -k <PASSPHRASE> -in 2016-04-11T07:25:30Z.tgz.aes -out restore.tgz -d
tar xf restore.tgz
```

## Usage

```
docker run -d [options] hudya/backup-to-s3 backup-once|schedule|restore
```

* Backup: Make a single backup and exit.
* Schedule: Schedule backups with using cron. 
* Restore: Restore a backup, 

## Options

| Name                                                | Operation        | Required | Description |
| -------------------------------------------------  | ----------------- | --------- | --------------------------- |
| -e AWS_ACCESS_KEY_ID=eu-central-1                  | all                   | yes |  Endpoint region (ideally where bucket is located)  |
| -e AWS_ACCESS_KEY_ID=&lt;AWS_KEY&gt;               | all                   | yes |  Your AWS key  |
| -e AWS_SECRET_ACCESS_KEY=&lt;AWS_SECRET&gt;        | all                   | yes | Your AWS secret |
| -e S3_PATH=s3://&lt;BUCKET_NAME&gt;/&lt;PATH&gt;/  | all                   | yes | S3 Bucket name and path. Should end with trailing slash. | 
| -e AES_PASSPHRASE=&lt;PASSPHRASE&gt;               | all                   | yes | Passphrase to generate AES-256-CBC encryption keys with. 
| -e WIPE_TARGET=false                               | restore               | no | Delete contents of target directory before restoring.
| -e POST_RESTORE_COMMAND=cmd                        | restore               | no | Command to run (in the container) after successfully restoring.
| -e VERSION=&lt;VERSION_TO_RESTORE&gt;              | restore               | yes | The version to restore, must be the full s3 object name without the `tgz.aes` suffix. | 
| -e PARAMS="--dry-run"                              | all                   | no  | Parameters to pass to the s3 command. [(full list here)](http://s3tools.org/usage) | 
| -e DATA_PATH=/data/                                | all                   | no  | Container's data folder. Default is `/data/`. Should end with trailing slash. | 
| -e PREFIX=prefix                                   | backup-once, schedule | no  | Prefix to encrypted tgz file name. The basename is a date stamp with a tgz.aes suffix | 
| -e CRON_SCHEDULE='5 3 \* \* \*'                    | schedule              | no  | Specifies when cron job runs, see [format](http://en.wikipedia.org/wiki/Cron). Default is 5 3 \* \* \*, runs every night at 03:05 |
| -v /path/to/backup:/data:ro                        | backup-once, schedule | yes | Mount target local folder to container's data folder. Content of this folder will be tar:ed, encrypted and uploaded to the S3 bucket. | 
| -v /path/to/restore:/data                          | restore               | yes | Mount target local folder to container's data folder. The restored files from the S3 bucket will overwrite all files in the /path/to/restore folder. Note that the folder will not be emptied first, leaving any no overwritten files as is. |


## Examples
 
Backup to S3 everyday at 12:00:

```bash
docker run -d \
	-e AWS_DEFAULT_REGION=eu-central-1 \
	-e AWS_ACCESS_KEY_ID=myawskey \
	-e AWS_SECRET_ACCESS_KEY=myawssecret \
	-e S3_PATH=s3://my-bucket/backup/ \
	-e AES_PASSPHRASE=secret \
	-e CRON_SCHEDULE='0 12 * * *' \
	-v /home/user/data:/data:ro \
	hudya/backup-to-s3 schedule
```


Backup once and then delete the container:

```bash
docker run --rm \
	-e AWS_DEFAULT_REGION=eu-central-1 \
	-e AWS_ACCESS_KEY_ID=myawskey \
	-e AWS_SECRET_ACCESS_KEY=myawssecret \
	-e S3_PATH=s3://my-bucket/backup/ \
	-e AES_PASSPHRASE=secret \
	-v /home/user/data:/data:ro \
	hudya/backup-to-s3 backup-once
```

Restore the backup from `2016-04-11T07:25:30Z` and then delete the container:

```bash
docker run --rm \
	-e AWS_DEFAULT_REGION=eu-central-1 \
	-e AWS_ACCESS_KEY_ID=myawskey \
	-e AWS_SECRET_ACCESS_KEY=myawssecret \
	-e S3_PATH=s3://my-bucket/backup/ \
		-e AES_PASSPHRASE=secret \
	-e VERSION=2016-04-11T07:25:30Z
	-v /home/user/data:/data \
	hudya/backup-to-s3 restore
```     
        
