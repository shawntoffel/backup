#!/bin/sh
set -e pipefail

timestamp=$(date +%Y%m%d%H%M%S)
backup_file="$BACKUP_NAME.$timestamp.tar.gz"

echo "starting file backup..."

echo "compressing..."
tar -zcvf "$backup_file" "$BACKUP_DIRECTORY"

encrypted_directory="$BACKUP_DIRECTORY/tmp/enc_backup_$timestamp"
mkdir -p "$encrypted_directory"

echo "encrypting..."
openssl enc -aes-256-cbc -pbkdf2 -pass file:"$ENCRYPTION_KEY_FILE" -in "$backup_file" -out "$encrypted_directory/$backup_file.enc"

echo "creating upload container..."
az storage container create --connection-string "$(cat "$AZ_CONNECTION_STRING_FILE")" --name "$AZ_CONTAINER" --only-show-errors

echo "uploading..."
az storage blob sync --connection-string "$(cat "$AZ_CONNECTION_STRING_FILE")" --container "$AZ_CONTAINER" --source "$encrypted_directory" --delete-destination "$AZ_BLOB_DELETE_DESTINATION"

echo "setting access tiers..."

for path in "$encrypted_directory"/*; do
    name=$(basename "$path")
    echo "setting access tier for blob '$name' to: $AZ_BLOB_ACCESS_TIER"
    az storage blob set-tier --connection-string "$(cat "$AZ_CONNECTION_STRING_FILE")" --container "$AZ_CONTAINER" --name "$name" --tier "$AZ_BLOB_ACCESS_TIER"
done

echo "cleaning up..."
rm -r "$encrypted_directory"

echo "finished file backup"