-- YTEmpire Complete Database Initialization Script
-- This script combines all schema files for complete database setup

\echo 'Starting YTEmpire database initialization...'

-- Include all schema files in order
\i /docker-entrypoint-initdb.d/01-extensions.sql
\i /docker-entrypoint-initdb.d/02-schemas.sql
\i /docker-entrypoint-initdb.d/03-users-schema.sql
\i /docker-entrypoint-initdb.d/04-content-schema.sql
\i /docker-entrypoint-initdb.d/05-analytics-schema.sql
\i /docker-entrypoint-initdb.d/06-campaigns-schema.sql
\i /docker-entrypoint-initdb.d/07-system-schema.sql
\i /docker-entrypoint-initdb.d/08-indexes-performance.sql
\i /docker-entrypoint-initdb.d/09-seed-data.sql

\echo 'Database initialization complete!'
\echo 'Creating database statistics...'

-- Update statistics for query optimization
ANALYZE;

\echo 'All done! YTEmpire database is ready for use.'