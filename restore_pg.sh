#!/bin/bash

# === CONFIG ===
DB_NAME="your_db_name"
DB_USER="your_db_user"
S3_BUCKET="s3://your-s3-bucket/postgres-backups"

# === INPUT VALIDATION ===
if [ -z "$1" ]; then
  echo "Usage: ./restore_pg.sh <backup-file-name.sql.gz>"
  echo "Example: ./restore_pg.sh mydb_2026-04-14_02-00-00.sql.gz"
  exit 1
fi

BACKUP_NAME="$1"
LOCAL_FILE="/tmp/$BACKUP_NAME"

echo "Starting restore process..."
echo "Backup file: $BACKUP_NAME"

# === DOWNLOAD FROM S3 ===
echo "Downloading backup from S3..."
aws s3 cp "$S3_BUCKET/$BACKUP_NAME" "$LOCAL_FILE"

if [ $? -ne 0 ]; then
  echo "Download failed!"
  exit 1
fi

echo "Download complete: $LOCAL_FILE"

# === RESTORE DATABASE ===
echo "Restoring database '$DB_NAME'..."
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

echo "Restore process completed successfully."
