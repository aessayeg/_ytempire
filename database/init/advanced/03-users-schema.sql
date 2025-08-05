-- 03-users-schema.sql: User management schema
-- YTEmpire MVP User Tables
-- Purpose: Authentication, authorization, and user profile management

\c ytempire_dev;

-- User roles enum
CREATE TYPE users.user_role AS ENUM ('admin', 'creator', 'analyst', 'viewer');
CREATE TYPE users.account_status AS ENUM ('active', 'inactive', 'suspended', 'pending');

-- Main users table
CREATE TABLE users.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    avatar_url VARCHAR(500),
    role users.user_role DEFAULT 'creator',
    status users.account_status DEFAULT 'pending',
    email_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_ip INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- User sessions table (for Redis sync)
CREATE TABLE users.sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- API keys for external integrations
CREATE TABLE users.api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) UNIQUE NOT NULL,
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    permissions JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE
);

-- User permissions (fine-grained access control)
CREATE TABLE users.permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
    resource_type VARCHAR(100) NOT NULL,
    resource_id UUID,
    action VARCHAR(50) NOT NULL,
    granted_by UUID REFERENCES users.users(id),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, resource_type, resource_id, action)
);

-- Audit log for security tracking
CREATE TABLE users.audit_log (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users.users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id UUID,
    ip_address INET,
    user_agent TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_users_email ON users.users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_username ON users.users(username) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role ON users.users(role) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_status ON users.users(status);
CREATE INDEX idx_sessions_user_id ON users.sessions(user_id) WHERE is_active = TRUE;
CREATE INDEX idx_sessions_token ON users.sessions(token_hash);
CREATE INDEX idx_sessions_expires ON users.sessions(expires_at) WHERE is_active = TRUE;
CREATE INDEX idx_api_keys_user ON users.api_keys(user_id) WHERE revoked_at IS NULL;
CREATE INDEX idx_permissions_user ON users.permissions(user_id);
CREATE INDEX idx_permissions_resource ON users.permissions(resource_type, resource_id);
CREATE INDEX idx_audit_log_user ON users.audit_log(user_id);
CREATE INDEX idx_audit_log_created ON users.audit_log(created_at);

-- Row Level Security
ALTER TABLE users.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE users.api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE users.permissions ENABLE ROW LEVEL SECURITY;

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION users.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users.users
    FOR EACH ROW
    EXECUTE FUNCTION users.update_updated_at();