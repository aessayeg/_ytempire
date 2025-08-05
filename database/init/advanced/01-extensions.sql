-- 01-extensions.sql: Enable required PostgreSQL extensions
-- YTEmpire MVP Database Setup
-- Author: Senior Database Architect
-- Purpose: Enable extensions for UUID generation, advanced indexing, and analytics

-- Connect to the ytempire_dev database
\c ytempire_dev;

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable trigram similarity search (for content searching)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Enable advanced indexing capabilities
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Enable cryptographic functions for secure password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Enable JSONB operators for YouTube API data
CREATE EXTENSION IF NOT EXISTS jsonb_plperl;

-- Enable time-series optimizations
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- Log successful extension setup
DO $$
BEGIN
    RAISE NOTICE 'PostgreSQL extensions successfully enabled for YTEmpire';
END $$;