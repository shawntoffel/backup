#!/bin/sh
set -eo pipefail

TIMESTAMP=$(date +%Y%m%d%H%M%S)

BACKUP_FILE="$BACKUP_NAME.$TIMESTAMP.tar.gz.enc"

PUBLIC_KEY_FILE=/var/secrets/public_key.pem
AZ_CONNECTION_STRING_FILE=/var/secrets/az_connection_string
MYSQL_PWD_FILE=/var/secrets/mysql_pwd

echo "starting mysql backup"

echo "creating config..."
cat > ~/.my.cnf <<EOF
[mysqldump]
host=$REMOTE_HOST
user=$MYSQL_USER
password=$(cat $MYSQL_PWD_FILE)
EOF

chmod 600 ~/.my.cnf
echo "finished creating config"

echo "beginning mysqldump..."
mysqldump --all-databases --single-transaction --quick --lock-tables=false | gzip | openssl smime -encrypt -binary -text -aes256 -out "$BACKUP_FILE" -outform DER "$PUBLIC_KEY_FILE"
echo "finished mysqldump"

echo "sha256sum: $(sha256sum "$BACKUP_FILE")"

echo "creating upload container..."
az storage container create --connection-string "$(cat $AZ_CONNECTION_STRING_FILE)" --name "$AZ_CONTAINER" 

echo "uploading..."
az storage blob upload --connection-string "$(cat $AZ_CONNECTION_STRING_FILE)" --container-name "$AZ_CONTAINER" --file "$BACKUP_FILE" --name "$BACKUP_FILE"

echo "finished mysql backup"