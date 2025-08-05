-- YTEmpire Users Schema
-- User management and authentication tables

-- users.accounts table
CREATE TABLE users.accounts (
    account_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email              VARCHAR(255) UNIQUE NOT NULL,
    username           VARCHAR(100) UNIQUE NOT NULL,
    password_hash      VARCHAR(255) NOT NULL,
    account_type       VARCHAR(50) NOT NULL CHECK (account_type IN ('creator', 'manager', 'admin')),
    account_status     VARCHAR(50) DEFAULT 'active' CHECK (account_status IN ('active', 'suspended', 'pending')),
    subscription_tier  VARCHAR(50) DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro', 'enterprise')),
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at      TIMESTAMP WITH TIME ZONE,
    email_verified     BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE
);

-- users.profiles table
CREATE TABLE users.profiles (
    profile_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id         UUID NOT NULL REFERENCES users.accounts(account_id) ON DELETE CASCADE,
    first_name         VARCHAR(100),
    last_name          VARCHAR(100),
    display_name       VARCHAR(150),
    bio                TEXT,
    avatar_url         VARCHAR(500),
    timezone           VARCHAR(50) DEFAULT 'UTC',
    language           VARCHAR(10) DEFAULT 'en',
    company_name       VARCHAR(200),
    website_url        VARCHAR(500),
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- users.sessions table
CREATE TABLE users.sessions (
    session_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id         UUID NOT NULL REFERENCES users.accounts(account_id) ON DELETE CASCADE,
    session_token      VARCHAR(255) UNIQUE NOT NULL,
    ip_address         INET,
    user_agent         TEXT,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at         TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active          BOOLEAN DEFAULT TRUE
);

-- Create indexes
CREATE INDEX idx_accounts_email ON users.accounts(email);
CREATE INDEX idx_accounts_username ON users.accounts(username);
CREATE INDEX idx_accounts_status ON users.accounts(account_status) WHERE account_status = 'active';
CREATE INDEX idx_accounts_type ON users.accounts(account_type);
CREATE INDEX idx_profiles_account_id ON users.profiles(account_id);
CREATE INDEX idx_sessions_token ON users.sessions(session_token);
CREATE INDEX idx_sessions_account_active ON users.sessions(account_id, is_active);
CREATE INDEX idx_sessions_expires ON users.sessions(expires_at) WHERE is_active = true;

-- Create triggers
CREATE TRIGGER update_accounts_timestamp 
    BEFORE UPDATE ON users.accounts 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_profiles_timestamp 
    BEFORE UPDATE ON users.profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Comments
COMMENT ON TABLE users.accounts IS 'Core user account management';
COMMENT ON TABLE users.profiles IS 'Extended user profile information';
COMMENT ON TABLE users.sessions IS 'User session management';

-- Grants
GRANT ALL ON SCHEMA users TO ytempire_user;
GRANT ALL ON ALL TABLES IN SCHEMA users TO ytempire_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA users TO ytempire_user;