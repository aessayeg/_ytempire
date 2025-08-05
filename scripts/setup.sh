#!/bin/bash

# YTEmpire Development Environment Setup Script
# This script bootstraps the complete development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ASCII Art Banner
echo -e "${BLUE}"
cat << "EOF"
 __   _______ _____                 _          
 \ \ / /_   _|  ___|               (_)         
  \ V /  | | | |__ _ __ ___  _ __  _ _ __ ___ 
   \ /   | | |  __| '_ ` _ \| '_ \| | '__/ _ \
   | |   | | | |__| | | | | | |_) | | | |  __/
   \_/   \_/ \____/_| |_| |_| .__/|_|_|  \___|
                             | |               
                             |_|               
EOF
echo -e "${NC}"

print_info "Starting YTEmpire Development Environment Setup..."

# Check prerequisites
print_info "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker Desktop first."
    exit 1
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi

print_success "Prerequisites check passed!"

# Create necessary directories
print_info "Creating project directories..."
mkdir -p {logs,uploads,temp,backups,nginx/ssl,monitoring/prometheus,monitoring/grafana/provisioning/datasources,monitoring/grafana/provisioning/dashboards,monitoring/grafana/dashboards}

# Check if .env file exists
if [ ! -f .env ]; then
    print_info "Creating .env file from template..."
    if [ -f .env.template ]; then
        cp .env.template .env
        print_warning "Please edit .env file with your configuration values!"
    else
        cp .env.example .env
        print_warning "Using .env.example as base. Please update with your values!"
    fi
else
    print_info ".env file already exists"
fi

# Generate SSL certificates for local HTTPS
print_info "Generating SSL certificates for local development..."
if [ ! -f nginx/ssl/cert.pem ] || [ ! -f nginx/ssl/key.pem ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/ssl/key.pem \
        -out nginx/ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=YTEmpire/OU=Development/CN=localhost"
    print_success "SSL certificates generated!"
else
    print_info "SSL certificates already exist"
fi

# Create monitoring configuration files
print_info "Setting up monitoring configuration..."

# Prometheus configuration
cat > monitoring/prometheus.yml << 'EOL'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis-exporter'
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'backend'
    static_configs:
      - targets: ['backend:9090']
EOL

# Grafana datasource
cat > monitoring/grafana/provisioning/datasources/prometheus.yml << 'EOL'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    orgId: 1
    url: http://prometheus:9090
    isDefault: true
    version: 1
    editable: true
EOL

# Filebeat configuration
cat > monitoring/filebeat.yml << 'EOL'
filebeat.config:
  modules:
    path: ${path.config}/modules.d/*.yml
    reload.enabled: false

filebeat.inputs:
  - type: container
    paths:
      - '/var/lib/docker/containers/*/*.log'
    processors:
      - add_docker_metadata:
          host: "unix:///var/run/docker.sock"

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  protocol: "http"

logging.level: info
logging.to_stderr: true
EOL

print_success "Monitoring configuration created!"

# Set proper permissions
print_info "Setting file permissions..."
chmod +x scripts/*.sh 2>/dev/null || true
chmod 600 nginx/ssl/*.pem 2>/dev/null || true

# Pull Docker images
print_info "Pulling Docker images..."
docker-compose pull

# Build custom images
print_info "Building custom Docker images..."
docker-compose build --no-cache

# Start services
print_info "Starting services..."
docker-compose up -d

# Wait for services to be healthy
print_info "Waiting for services to be healthy..."
sleep 10

# Check service health
print_info "Checking service health..."
./scripts/health-check.sh 2>/dev/null || echo "Health check script not found, skipping..."

# Show access URLs
echo ""
print_success "YTEmpire Development Environment is ready!"
echo ""
echo -e "${GREEN}Access URLs:${NC}"
echo -e "  Frontend:        ${BLUE}http://localhost:3000${NC}"
echo -e "  Backend API:     ${BLUE}http://localhost:5000${NC}"
echo -e "  pgAdmin:         ${BLUE}http://localhost:8080${NC}"
echo -e "  Redis Commander: ${BLUE}http://localhost:8081${NC}"
echo -e "  MailHog:         ${BLUE}http://localhost:8025${NC}"
echo -e "  Prometheus:      ${BLUE}http://localhost:9090${NC}"
echo -e "  Grafana:         ${BLUE}http://localhost:3001${NC} (admin/admin)"
echo -e "  Kibana:          ${BLUE}http://localhost:5601${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update .env file with your API keys and configuration"
echo "2. Run './scripts/logs.sh' to view service logs"
echo "3. Access pgAdmin and verify database connection"
echo "4. Start developing!"
echo ""
print_info "Happy coding! 🚀"