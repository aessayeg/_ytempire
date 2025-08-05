-- YTEmpire Database Extensions
-- Enable required PostgreSQL extensions

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Full text search
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- JSON validation
CREATE EXTENSION IF NOT EXISTS "plpgsql";

-- Performance monitoring
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enable gen_random_uuid() function
CREATE EXTENSION IF NOT EXISTS "pgcrypto";