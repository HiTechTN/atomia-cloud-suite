#!/bin/bash

# =============================================================================
# ATOMIA CLOUD SUITE - Backup Script
# Automated daily backups for all persistent data volumes
# =============================================================================

set -e

# Configuration
BACKUP_DIR="./backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_PATH="$BACKUP_DIR/$DATE"
RETENTION_DAYS=7

# Create backup directory
mkdir -p "$BACKUP_PATH"

echo "Starting Atomia Cloud Suite backup..."
echo "Date: $DATE"

# List of directories to backup
DATA_DIRS=("data" "projects" "continue" "monitoring")

# Pause containers for consistent backup (optional, comment out for hot backup)
# echo "Pausing containers..."
# docker compose pause

for dir in "${DATA_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Backing up $dir..."
        tar -czf "$BACKUP_PATH/${dir}.tar.gz" "$dir"
    fi
done

# Resume containers
# echo "Resuming containers..."
# docker compose unpause

# Clean old backups
echo "Cleaning backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} +

echo "Backup completed successfully!"
echo "Location: $BACKUP_PATH"

# =============================================================================
# OFF-SITE STORAGE (Optional)
# Uncomment and configure for secure off-site storage
# =============================================================================
# Example: rclone sync "$BACKUP_DIR" remote:atomia-backups
# Example: aws s3 sync "$BACKUP_DIR" s3://my-atomia-backups
