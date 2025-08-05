-- 07-roles-permissions.sql: Database roles and access control
-- YTEmpire MVP Security Configuration
-- Purpose: Create application user, roles, and grant appropriate permissions

\c ytempire_dev;

-- Create application role for connection pooling
CREATE ROLE ytempire_app WITH LOGIN PASSWORD 'ytempire_app_2024!Dev';
ALTER ROLE ytempire_app SET statement_timeout = '30s';
ALTER ROLE ytempire_app SET lock_timeout = '10s';
ALTER ROLE ytempire_app SET idle_in_transaction_session_timeout = '10min';

-- Create read-only role for analytics
CREATE ROLE ytempire_readonly WITH LOGIN PASSWORD 'ytempire_read_2024!Dev';

-- Create admin role for migrations
CREATE ROLE ytempire_admin WITH LOGIN PASSWORD 'ytempire_admin_2024!Dev' CREATEDB CREATEROLE;

-- Grant connect privileges
GRANT CONNECT ON DATABASE ytempire_dev TO ytempire_app, ytempire_readonly;

-- Grant schema usage
GRANT USAGE ON SCHEMA public, users, content, analytics, campaigns TO ytempire_app, ytempire_readonly;
GRANT CREATE ON SCHEMA public, users, content, analytics, campaigns TO ytempire_admin;

-- Grant table privileges to application role
-- Users schema
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA users TO ytempire_app;
GRANT SELECT ON ALL TABLES IN SCHEMA users TO ytempire_readonly;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA users TO ytempire_app;

-- Content schema
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA content TO ytempire_app;
GRANT SELECT ON ALL TABLES IN SCHEMA content TO ytempire_readonly;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA content TO ytempire_app;

-- Analytics schema
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA analytics TO ytempire_app;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO ytempire_readonly;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA analytics TO ytempire_app;

-- Campaigns schema
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA campaigns TO ytempire_app;
GRANT SELECT ON ALL TABLES IN SCHEMA campaigns TO ytempire_readonly;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA campaigns TO ytempire_app;

-- Grant future table privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA users GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ytempire_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA content GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ytempire_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ytempire_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA campaigns GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ytempire_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA users GRANT SELECT ON TABLES TO ytempire_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA content GRANT SELECT ON TABLES TO ytempire_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT ON TABLES TO ytempire_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA campaigns GRANT SELECT ON TABLES TO ytempire_readonly;

-- Grant sequence privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA users GRANT USAGE, SELECT ON SEQUENCES TO ytempire_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA content GRANT USAGE, SELECT ON SEQUENCES TO ytempire_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT USAGE, SELECT ON SEQUENCES TO ytempire_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA campaigns GRANT USAGE, SELECT ON SEQUENCES TO ytempire_app;

-- Grant execute on functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA users TO ytempire_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA analytics TO ytempire_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA campaigns TO ytempire_app;

-- Row Level Security Policies
-- Users can only see their own data
CREATE POLICY users_own_data ON users.users
    FOR ALL TO ytempire_app
    USING (id = current_setting('app.current_user_id')::UUID OR 
           EXISTS (SELECT 1 FROM users.users WHERE id = current_setting('app.current_user_id')::UUID AND role = 'admin'));

CREATE POLICY sessions_own_data ON users.sessions
    FOR ALL TO ytempire_app
    USING (user_id = current_setting('app.current_user_id')::UUID OR 
           EXISTS (SELECT 1 FROM users.users WHERE id = current_setting('app.current_user_id')::UUID AND role = 'admin'));

CREATE POLICY api_keys_own_data ON users.api_keys
    FOR ALL TO ytempire_app
    USING (user_id = current_setting('app.current_user_id')::UUID);

-- Create database link for cross-database queries (if needed)
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Log successful setup
DO $$
BEGIN
    RAISE NOTICE 'Database roles and permissions successfully configured';
    RAISE NOTICE 'Application user: ytempire_app';
    RAISE NOTICE 'Read-only user: ytempire_readonly';
    RAISE NOTICE 'Admin user: ytempire_admin';
END $$;