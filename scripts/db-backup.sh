#!/bin/sh
# Database Backup Script for YTEmpire
# Runs daily backups of PostgreSQL and Redis

set -e

# Configuration
BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# PostgreSQL Backup
echo "Starting PostgreSQL backup..."
PGPASSWORD=$POSTGRES_PASSWORD pg_dump \
    -h postgresql \
    -U $POSTGRES_USER \
    -d $POSTGRES_DB \
    -Fc \
    -f "$BACKUP_DIR/postgresql_${TIMESTAMP}.dump"

# Compress the backup
gzip "$BACKUP_DIR/postgresql_${TIMESTAMP}.dump"

echo "PostgreSQL backup completed: postgresql_${TIMESTAMP}.dump.gz"

# Redis Backup (connect to Redis and trigger BGSAVE)
echo "Starting Redis backup..."
redis-cli -h redis BGSAVE
sleep 5

# Copy Redis dump file
if [ -f "/data/ytempire_dump.rdb" ]; then
    cp "/data/ytempire_dump.rdb" "$BACKUP_DIR/redis_${TIMESTAMP}.rdb"
    gzip "$BACKUP_DIR/redis_${TIMESTAMP}.rdb"
    echo "Redis backup completed: redis_${TIMESTAMP}.rdb.gz"
fi

# Clean up old backups
echo "Cleaning up old backups..."
find $BACKUP_DIR -name "*.gz" -type f -mtime +$RETENTION_DAYS -exec rm {} \;

echo "Backup process completed at $(date)"

# Create backup metadata
cat > "$BACKUP_DIR/backup_${TIMESTAMP}.json" <<EOF
{
    "timestamp": "${TIMESTAMP}",
    "date": "$(date -Iseconds)",
    "postgresql_backup": "postgresql_${TIMESTAMP}.dump.gz",
    "redis_backup": "redis_${TIMESTAMP}.rdb.gz",
    "retention_days": ${RETENTION_DAYS}
}
EOF