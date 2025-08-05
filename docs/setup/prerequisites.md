# Prerequisites & System Requirements

This guide covers all prerequisites and system requirements needed to run YTEmpire MVP successfully.

## Table of Contents

- [Hardware Requirements](#hardware-requirements)
- [Software Prerequisites](#software-prerequisites)
- [Account Requirements](#account-requirements)
- [Network Requirements](#network-requirements)
- [Environment Preparation](#environment-preparation)
- [Verification Steps](#verification-steps)

## Hardware Requirements

### Minimum Requirements

- **CPU**: 4 cores (x86_64 architecture)
- **RAM**: 8GB
- **Storage**: 20GB free space (SSD recommended)
- **Network**: Stable internet connection (10 Mbps+)

### Recommended Requirements

- **CPU**: 8+ cores
- **RAM**: 16GB
- **Storage**: 50GB SSD
- **Network**: 25+ Mbps connection

### Resource Allocation by Service

| Service         | RAM Usage | CPU Usage | Disk Space |
| --------------- | --------- | --------- | ---------- |
| PostgreSQL      | 512MB-1GB | 1 core    | 5GB        |
| Redis           | 256MB     | 0.5 core  | 1GB        |
| Backend API     | 512MB     | 1 core    | 500MB      |
| Frontend        | 512MB     | 1 core    | 500MB      |
| Nginx           | 128MB     | 0.5 core  | 100MB      |
| Docker overhead | 1GB       | 0.5 core  | 10GB       |

## Software Prerequisites

### Operating System Support

YTEmpire supports the following operating systems:

#### macOS

- macOS 11 (Big Sur) or later
- Apple Silicon (M1/M2) or Intel processors

#### Linux

- Ubuntu 20.04 LTS or later
- Debian 10 or later
- CentOS/RHEL 8 or later
- Fedora 34 or later

#### Windows

- Windows 10 Pro/Enterprise (version 2004 or later)
- Windows 11
- WSL2 enabled and configured

### Required Software

#### 1. Docker Desktop

**Version**: 20.10 or later

##### Installation:

**macOS/Windows:**

```bash
# Download from Docker website
open https://www.docker.com/products/docker-desktop

# Verify installation
docker --version
docker-compose --version
```

**Linux:**

```bash
# Install Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker-compose --version
```

#### 2. Git

**Version**: 2.30 or later

```bash
# macOS
brew install git

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install git

# Windows
winget install Git.Git

# Verify installation
git --version
```

#### 3. VS Code (Recommended)

**Version**: Latest stable

```bash
# Download from
open https://code.visualstudio.com/download

# Or via command line (macOS)
brew install --cask visual-studio-code

# Linux
snap install code --classic

# Windows
winget install Microsoft.VisualStudioCode
```

#### 4. Node.js (Optional for local development)

**Version**: 18 LTS or later

```bash
# Using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18

# Verify installation
node --version
npm --version
```

#### 5. Python (Optional for scripts)

**Version**: 3.8 or later

```bash
# macOS
brew install python@3.11

# Ubuntu/Debian
sudo apt-get install python3 python3-pip

# Windows
winget install Python.Python.3.11

# Verify installation
python3 --version
pip3 --version
```

## Account Requirements

### 1. GitHub Account

- Required for repository access
- SSH key configured (recommended)

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key
cat ~/.ssh/id_ed25519.pub
# Add this key to GitHub: Settings → SSH and GPG keys
```

### 2. Google Cloud Console Account

Required for YouTube API access:

1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable YouTube Data API v3
4. Enable YouTube Analytics API
5. Create OAuth 2.0 credentials
6. Download credentials JSON

### 3. Docker Hub Account (Optional)

- Only required if using private Docker images
- Sign up at [hub.docker.com](https://hub.docker.com/)

```bash
# Login to Docker Hub
docker login
```

## Network Requirements

### Port Availability

Ensure the following ports are available:

| Port | Service     | Check Command                                 |
| ---- | ----------- | --------------------------------------------- |
| 3000 | Frontend    | `lsof -i :3000` or `netstat -an \| grep 3000` |
| 5000 | Backend API | `lsof -i :5000` or `netstat -an \| grep 5000` |
| 5432 | PostgreSQL  | `lsof -i :5432` or `netstat -an \| grep 5432` |
| 6379 | Redis       | `lsof -i :6379` or `netstat -an \| grep 6379` |
| 80   | Nginx HTTP  | `lsof -i :80` or `netstat -an \| grep 80`     |
| 443  | Nginx HTTPS | `lsof -i :443` or `netstat -an \| grep 443`   |
| 8080 | pgAdmin     | `lsof -i :8080` or `netstat -an \| grep 8080` |

### Firewall Configuration

```bash
# macOS
# Check firewall status
sudo pfctl -s info

# Linux (UFW)
sudo ufw status
# Allow Docker
sudo ufw allow from 172.16.0.0/12

# Windows
# Check Windows Defender Firewall
netsh advfirewall show allprofiles
```

### External API Access

Ensure access to:

- YouTube API endpoints: `https://www.googleapis.com`
- Docker Hub: `https://hub.docker.com`
- npm registry: `https://registry.npmjs.org`
- GitHub: `https://github.com`

## Environment Preparation

### 1. Docker Configuration

#### Docker Desktop Settings (GUI):

1. Open Docker Desktop
2. Go to Settings/Preferences
3. Configure:
   - **Resources**:
     - CPUs: 4+ cores
     - Memory: 8GB+
     - Swap: 2GB
     - Disk image size: 40GB+
   - **File Sharing**: Add project directory
   - **Network**: Use default settings

#### Docker Daemon Configuration:

```json
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false,
  "features": {
    "buildkit": true
  }
}
```

### 2. File System Permissions

```bash
# Clone repository
git clone https://github.com/yourusername/ytempire.git
cd ytempire

# Set correct permissions
chmod +x scripts/*.sh
chmod 755 database/init/*.sql

# Create required directories
mkdir -p uploads temp logs backups
```

### 3. Environment Variables

Create `.env` file from template:

```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

Required environment variables:

```env
# Database
POSTGRES_USER=ytempire_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=ytempire_dev

# Redis
REDIS_PASSWORD=your_redis_password

# JWT
JWT_SECRET=your_jwt_secret_key

# YouTube API
YOUTUBE_API_KEY=your_youtube_api_key
YOUTUBE_CLIENT_ID=your_oauth_client_id
YOUTUBE_CLIENT_SECRET=your_oauth_client_secret

# Application
NODE_ENV=development
PORT=5000
CLIENT_URL=http://localhost:3000
```

## Verification Steps

### 1. System Check Script

Create and run verification script:

```bash
#!/bin/bash
# verify-prerequisites.sh

echo "🔍 Checking Prerequisites..."

# Check Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker: $(docker --version)"
else
    echo "❌ Docker not installed"
    exit 1
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose: $(docker-compose --version)"
else
    echo "❌ Docker Compose not installed"
    exit 1
fi

# Check Git
if command -v git &> /dev/null; then
    echo "✅ Git: $(git --version)"
else
    echo "❌ Git not installed"
    exit 1
fi

# Check available memory
if [[ "$OSTYPE" == "darwin"* ]]; then
    MEM=$(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024}')
else
    MEM=$(free -g | awk '/^Mem:/{print $2}')
fi
echo "✅ Available RAM: ${MEM}GB"

# Check disk space
DISK=$(df -h . | awk 'NR==2 {print $4}')
echo "✅ Available Disk: ${DISK}"

# Check ports
for port in 3000 5000 5432 6379 80 443 8080; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️  Port $port is in use"
    else
        echo "✅ Port $port is available"
    fi
done

echo "✅ Prerequisites check complete!"
```

### 2. Docker Test

```bash
# Test Docker installation
docker run hello-world

# Test Docker Compose
docker-compose version

# Check Docker daemon
docker system info
```

### 3. Network Test

```bash
# Test external connectivity
curl -I https://www.googleapis.com
curl -I https://hub.docker.com
curl -I https://github.com

# Test DNS resolution
nslookup googleapis.com
```

## Troubleshooting Common Issues

### Docker Issues

#### Docker daemon not running

```bash
# macOS/Windows
# Open Docker Desktop application

# Linux
sudo systemctl start docker
sudo systemctl enable docker
```

#### Permission denied errors

```bash
# Linux
sudo usermod -aG docker $USER
newgrp docker

# macOS/Windows
# Ensure Docker Desktop is running with proper permissions
```

### Port Conflicts

#### Find and kill processes using ports

```bash
# Find process using port
lsof -i :PORT_NUMBER
# or
netstat -tulpn | grep PORT_NUMBER

# Kill process
kill -9 PID
```

### WSL2 Issues (Windows)

#### Enable WSL2

```powershell
# Run as Administrator
wsl --install
wsl --set-default-version 2

# Install Ubuntu
wsl --install -d Ubuntu-20.04
```

#### Configure WSL2 resources

Create `%USERPROFILE%\.wslconfig`:

```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
```

## Next Steps

Once all prerequisites are met:

1. Continue to [Environment Setup](environment-setup.md)
2. Configure your [VS Code environment](vscode-setup.md)
3. Initialize the [database](database-setup.md)

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting Guide](../troubleshooting/common-issues.md)
2. Search existing [GitHub Issues](https://github.com/yourusername/ytempire/issues)
3. Create a new issue with:
   - System information
   - Error messages
   - Steps to reproduce

---

[← Back to README](../../README.md) | [Next: Environment Setup →](environment-setup.md)
