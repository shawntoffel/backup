#!/bin/sh
set -e pipefail

TIMESTAMP=$(date +%Y%m%d%H%M%S)

BACKUP_DIR=backups
BACKUP_FILE="$BACKUP_NAME.$TIMESTAMP.tar.gz"

echo "starting cockroachdb backup"
mkdir -p "$BACKUP_DIR"

echo "looking for databases..."
databases=$(cockroach sql --host "$REMOTE_HOST" --insecure -e "show databases;" | tail -n +2)

echo "creating backups..."
for database in $databases; do
    echo "creating backup for: $database"

    cockroach dump --host "$REMOTE_HOST" --insecure "$database" | gzip | openssl smime -encrypt -binary -text -aes256 -out "$BACKUP_DIR/$database.sql.tar.gz.enc" -outform DER "$PUBLIC_KEY_FILE"
done

if [ -z "$(ls -A $BACKUP_DIR)" ]; then 
    echo "no backups to upload"
    exit
fi

echo "compressing to single file..."
tar -czf "$BACKUP_FILE" "$BACKUP_DIR"

echo "sha256sum: $(sha256sum "$BACKUP_FILE")"

echo "creating upload container..."
az storage container create --connection-string "$(cat "$AZ_CONNECTION_STRING_FILE")" --name "$AZ_CONTAINER" 

echo "uploading..."
az storage blob upload --connection-string "$(cat "$AZ_CONNECTION_STRING_FILE")" --container-name "$AZ_CONTAINER" --file "$BACKUP_FILE" --name "$BACKUP_FILE"

echo "setting blob access tier..."
az storage blob set-tier --connection-string "$(cat "$AZ_CONNECTION_STRING_FILE")" --container "$AZ_CONTAINER" --name "$BACKUP_FILE" --tier "$AZ_BLOB_ACCESS_TIER"

echo "finished cockroachdb backup"
