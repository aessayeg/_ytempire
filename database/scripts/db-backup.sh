#!/bin/sh
# YTEmpire Database Backup Script
# Performs daily backups of PostgreSQL and Redis

set -e

# Configuration
BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

echo "Starting YTEmpire database backup at $(date)"

# PostgreSQL Backup
echo "Backing up PostgreSQL..."
PGPASSWORD=$POSTGRES_PASSWORD pg_dump \
    -h $POSTGRES_HOST \
    -U $POSTGRES_USER \
    -d $POSTGRES_DB \
    -Fc \
    -f "$BACKUP_DIR/postgresql_${TIMESTAMP}.dump"

# Compress the backup
gzip "$BACKUP_DIR/postgresql_${TIMESTAMP}.dump"
echo "PostgreSQL backup completed: postgresql_${TIMESTAMP}.dump.gz"

# Redis Backup
echo "Backing up Redis..."
redis-cli -h redis BGSAVE

# Wait for background save to complete
sleep 5

# Copy Redis dump file
if [ -f "/data/ytempire_dump.rdb" ]; then
    cp "/data/ytempire_dump.rdb" "$BACKUP_DIR/redis_${TIMESTAMP}.rdb"
    gzip "$BACKUP_DIR/redis_${TIMESTAMP}.rdb"
    echo "Redis backup completed: redis_${TIMESTAMP}.rdb.gz"
else
    echo "Warning: Redis dump file not found"
fi

# Clean up old backups
echo "Cleaning up old backups..."
find $BACKUP_DIR -name "*.gz" -type f -mtime +$RETENTION_DAYS -exec rm {} \;

# Create backup metadata
cat > "$BACKUP_DIR/backup_${TIMESTAMP}.json" <<EOF
{
    "timestamp": "${TIMESTAMP}",
    "date": "$(date -Iseconds)",
    "postgresql_backup": "postgresql_${TIMESTAMP}.dump.gz",
    "redis_backup": "redis_${TIMESTAMP}.rdb.gz",
    "retention_days": ${RETENTION_DAYS},
    "database": "${POSTGRES_DB}",
    "schemas": ["users", "content", "analytics", "campaigns", "system"]
}
EOF

# Calculate backup sizes
PG_SIZE=$(stat -c%s "$BACKUP_DIR/postgresql_${TIMESTAMP}.dump.gz" 2>/dev/null || echo "0")
REDIS_SIZE=$(stat -c%s "$BACKUP_DIR/redis_${TIMESTAMP}.rdb.gz" 2>/dev/null || echo "0")

echo "Backup summary:"
echo "  PostgreSQL: $(numfmt --to=iec-i --suffix=B $PG_SIZE)"
echo "  Redis: $(numfmt --to=iec-i --suffix=B $REDIS_SIZE)"
echo "Backup process completed at $(date)"