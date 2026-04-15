#!/bin/bash

# === CONFIG ===
DB_NAME="your-db-name"
DB_USER="your-db-user"
S3_BUCKET="s3://your-s3-bucket-name/postgres-backups"

# === INPUT VALIDATION ===
if [ -z "$1" ]; then
  echo "Usage: ./restore_pg.sh <backup-file-name.sql.gz>"
  exit 1
fi

BACKUP_NAME="$1"
LOCAL_FILE="/tmp/$BACKUP_NAME"

echo "Starting FULL restore process..."
echo "Backup file: $BACKUP_NAME"

# === DOWNLOAD FROM S3 ===
echo "Downloading backup from S3..."
aws s3 cp "$S3_BUCKET/$BACKUP_NAME" "$LOCAL_FILE"
if [ $? -ne 0 ]; then
  echo "Download failed!"
  exit 1
fi
echo "Download complete: $LOCAL_FILE"

# === DROP DATABASE ===
echo "Dropping existing database '$DB_NAME'..."
sudo -u postgres dropdb "$DB_NAME" 2>/dev/null

# === RECREATE DATABASE ===
echo "Recreating database '$DB_NAME' with owner '$DB_USER'..."
sudo -u postgres createdb "$DB_NAME" -O "$DB_USER"

# === FIX SCHEMA OWNERSHIP ===
echo "Fixing schema ownership..."
sudo -u postgres psql -d "$DB_NAME" -c "ALTER SCHEMA public OWNER TO $DB_USER;"

# === RESTORE DATABASE ===
echo "Restoring database..."
gunzip -c "$LOCAL_FILE" | psql -U "$DB_USER" "$DB_NAME"
if [ $? -ne 0 ]; then
  echo "Restore failed!"
  rm "$LOCAL_FILE"
  exit 1
fi

echo "Restore successful."

# === CLEANUP ===
rm "$LOCAL_FILE"
echo "Local backup file removed."

echo "FULL restore process completed successfully."
