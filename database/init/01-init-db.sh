#!/bin/bash
# YTEmpire Database Initialization Script
# Initializes PostgreSQL with the complete schema

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting YTEmpire Database Initialization...${NC}"

# Function to execute SQL file
execute_sql_file() {
    local file=$1
    local description=$2
    
    echo -e "${YELLOW}Executing: ${description}${NC}"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ${description} completed successfully${NC}"
    else
        echo -e "${RED}✗ ${description} failed${NC}"
        exit 1
    fi
}

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
    sleep 2
done

# Execute schema files in order
SCHEMA_DIR="/docker-entrypoint-initdb.d/schema"

# Check if schema directory exists
if [ ! -d "$SCHEMA_DIR" ]; then
    echo -e "${RED}Schema directory not found: $SCHEMA_DIR${NC}"
    exit 1
fi

# Execute each schema file in order
execute_sql_file "$SCHEMA_DIR/01-extensions.sql" "Installing PostgreSQL extensions"
execute_sql_file "$SCHEMA_DIR/02-schemas.sql" "Creating database schemas"
execute_sql_file "$SCHEMA_DIR/03-users-schema.sql" "Creating users schema tables"
execute_sql_file "$SCHEMA_DIR/04-content-schema.sql" "Creating content schema tables"
execute_sql_file "$SCHEMA_DIR/05-analytics-schema.sql" "Creating analytics schema tables with partitioning"
execute_sql_file "$SCHEMA_DIR/06-campaigns-schema.sql" "Creating campaigns schema tables"
execute_sql_file "$SCHEMA_DIR/07-system-schema.sql" "Creating system schema tables"
execute_sql_file "$SCHEMA_DIR/08-indexes-performance.sql" "Creating performance indexes and materialized views"
execute_sql_file "$SCHEMA_DIR/09-seed-data.sql" "Loading development seed data"

# Create additional database users if needed
echo -e "${YELLOW}Creating additional database users...${NC}"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create read-only user for analytics
    CREATE USER ytempire_readonly WITH PASSWORD 'readonly_pass';
    GRANT CONNECT ON DATABASE $POSTGRES_DB TO ytempire_readonly;
    GRANT USAGE ON SCHEMA users, content, analytics, campaigns, system TO ytempire_readonly;
    GRANT SELECT ON ALL TABLES IN SCHEMA users, content, analytics, campaigns, system TO ytempire_readonly;
    
    -- Create application user if not exists
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'ytempire_user') THEN
            CREATE USER ytempire_user WITH PASSWORD 'ytempire_pass';
        END IF;
    END
    \$\$;
    
    -- Grant full permissions to application user
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO ytempire_user;
    GRANT ALL ON SCHEMA users, content, analytics, campaigns, system TO ytempire_user;
    GRANT ALL ON ALL TABLES IN SCHEMA users, content, analytics, campaigns, system TO ytempire_user;
    GRANT ALL ON ALL SEQUENCES IN SCHEMA users, content, analytics, campaigns, system TO ytempire_user;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA users, content, analytics, campaigns, system TO ytempire_user;
    
    -- Alter default privileges for future objects
    ALTER DEFAULT PRIVILEGES IN SCHEMA users, content, analytics, campaigns, system 
        GRANT ALL ON TABLES TO ytempire_user;
    ALTER DEFAULT PRIVILEGES IN SCHEMA users, content, analytics, campaigns, system 
        GRANT ALL ON SEQUENCES TO ytempire_user;
    ALTER DEFAULT PRIVILEGES IN SCHEMA users, content, analytics, campaigns, system 
        GRANT EXECUTE ON FUNCTIONS TO ytempire_user;
EOSQL

# Set up automated maintenance
echo -e "${YELLOW}Setting up automated maintenance...${NC}"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create maintenance function
    CREATE OR REPLACE FUNCTION perform_database_maintenance()
    RETURNS VOID AS \$\$
    BEGIN
        -- Update table statistics
        ANALYZE;
        
        -- Create new partitions if needed
        PERFORM auto_create_monthly_partitions();
        
        -- Refresh materialized views
        PERFORM refresh_analytics_views();
    END;
    \$\$ LANGUAGE plpgsql;
    
    -- Note: pg_cron or external scheduler needed to run this periodically
    COMMENT ON FUNCTION perform_database_maintenance() IS 'Run daily for database maintenance';
EOSQL

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}YTEmpire Database Initialization Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Database: $POSTGRES_DB"
echo "User: ytempire_user"
echo "Schemas created: users, content, analytics, campaigns, system"
echo ""
echo "To connect:"
echo "  psql -h localhost -U ytempire_user -d $POSTGRES_DB"
echo ""
echo -e "${YELLOW}Note: Default password for test accounts is 'password123'${NC}"