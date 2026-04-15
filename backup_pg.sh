#!/bin/bash

# === CONFIG ===
DB_NAME="your_database_name"
DB_USER="your_database_user"
S3_BUCKET="s3://your-s3-bucket/postgres-backups"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="/tmp/${DB_NAME}_${DATE}.sql.gz"

# === BACKUP ===
echo "Creating PostgreSQL backup..."
pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"

if [ $? -ne 0 ]; then
  echo "Backup failed!"
  exit 1
fi

echo "Backup created: $BACKUP_FILE"

# === UPLOAD TO S3 ===
echo "Uploading to S3..."
aws s3 cp "$BACKUP_FILE" "$S3_BUCKET/"

if [ $? -ne 0 ]; then
  echo "Upload failed!"
  exit 1
fi

echo "Upload successful."

# === CLEANUP ===
rm "$BACKUP_FILE"
echo "Local backup removed."

echo "Backup completed successfully."

# this script requires the AWS CLI to be installed and configured with appropriate permissions 
# to access the S3 bucket. Additionally,
# ensure that the PostgreSQL client tools are installed on the machine where this script is run.
# for securety reasons, create a dedicated aws user with costum permissions to access only the specific S3 bucket used for backups.
