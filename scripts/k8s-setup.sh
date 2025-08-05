#!/bin/bash

# YTEmpire Kubernetes Setup Script
# This script sets up a local Kubernetes cluster using kind and deploys YTEmpire

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="ytempire-dev"
NAMESPACE="ytempire-dev"

echo -e "${BLUE}YTEmpire Kubernetes Setup${NC}"
echo "================================"

# Check prerequisites
check_prerequisites() {
    echo -e "\n${YELLOW}Checking prerequisites...${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker is installed${NC}"
    
    # Check kind
    if ! command -v kind &> /dev/null; then
        echo -e "${YELLOW}kind is not installed. Installing...${NC}"
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
    echo -e "${GREEN}✓ kind is installed${NC}"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${YELLOW}kubectl is not installed. Installing...${NC}"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
    echo -e "${GREEN}✓ kubectl is installed${NC}"
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        echo -e "${YELLOW}Helm is not installed. Installing...${NC}"
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    echo -e "${GREEN}✓ Helm is installed${NC}"
}

# Create kind cluster
create_cluster() {
    echo -e "\n${YELLOW}Creating kind cluster...${NC}"
    
    # Check if cluster already exists
    if kind get clusters | grep -q "$CLUSTER_NAME"; then
        echo -e "${YELLOW}Cluster $CLUSTER_NAME already exists. Deleting...${NC}"
        kind delete cluster --name=$CLUSTER_NAME
    fi
    
    # Create cluster
    kind create cluster --config=kind-config.yaml --name=$CLUSTER_NAME
    
    # Set kubectl context
    kubectl cluster-info --context kind-$CLUSTER_NAME
    
    echo -e "${GREEN}✓ Cluster created successfully${NC}"
}

# Install ingress controller
install_ingress() {
    echo -e "\n${YELLOW}Installing NGINX Ingress Controller...${NC}"
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    # Wait for ingress to be ready
    echo "Waiting for ingress controller to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
    
    echo -e "${GREEN}✓ Ingress controller installed${NC}"
}

# Create storage directories
create_storage_dirs() {
    echo -e "\n${YELLOW}Creating storage directories...${NC}"
    
    # Create local directories for persistent volumes
    mkdir -p k8s-data/{postgresql,redis,logs}
    mkdir -p uploads
    
    echo -e "${GREEN}✓ Storage directories created${NC}"
}

# Deploy YTEmpire
deploy_ytempire() {
    echo -e "\n${YELLOW}Deploying YTEmpire...${NC}"
    
    # Apply base manifests using kustomize
    kubectl apply -k kubernetes/base/
    
    # Wait for namespace to be created
    kubectl wait --for=condition=Active namespace/$NAMESPACE --timeout=60s
    
    # Wait for deployments to be ready
    echo "Waiting for deployments to be ready..."
    kubectl wait --namespace $NAMESPACE \
        --for=condition=available \
        --timeout=300s \
        deployment --all
    
    # Wait for StatefulSets to be ready
    echo "Waiting for StatefulSets to be ready..."
    kubectl wait --namespace $NAMESPACE \
        --for=condition=ready \
        --timeout=300s \
        pod -l app=postgresql
    
    kubectl wait --namespace $NAMESPACE \
        --for=condition=ready \
        --timeout=300s \
        pod -l app=redis
    
    echo -e "${GREEN}✓ YTEmpire deployed successfully${NC}"
}

# Configure hosts file
configure_hosts() {
    echo -e "\n${YELLOW}Configuring hosts file...${NC}"
    
    # Add entries to /etc/hosts
    if ! grep -q "ytempire.local" /etc/hosts; then
        echo "127.0.0.1 ytempire.local api.ytempire.local pgadmin.ytempire.local mailhog.ytempire.local" | sudo tee -a /etc/hosts
    fi
    
    echo -e "${GREEN}✓ Hosts file configured${NC}"
}

# Display access information
display_info() {
    echo -e "\n${GREEN}================================${NC}"
    echo -e "${GREEN}YTEmpire Setup Complete!${NC}"
    echo -e "${GREEN}================================${NC}"
    
    echo -e "\n${BLUE}Access URLs:${NC}"
    echo "  Frontend:    http://ytempire.local"
    echo "  Backend API: http://api.ytempire.local"
    echo "  pgAdmin:     http://pgadmin.ytempire.local (admin@ytempire.local / admin123)"
    echo "  MailHog:     http://mailhog.ytempire.local"
    
    echo -e "\n${BLUE}Direct NodePort Access:${NC}"
    echo "  PostgreSQL:  localhost:30000 (ytempire_user / ytempire_pass)"
    echo "  Redis:       localhost:30001"
    echo "  pgAdmin:     localhost:30002"
    echo "  MailHog UI:  localhost:30003"
    
    echo -e "\n${BLUE}Useful Commands:${NC}"
    echo "  View pods:     kubectl get pods -n $NAMESPACE"
    echo "  View logs:     kubectl logs -n $NAMESPACE <pod-name>"
    echo "  Port forward:  kubectl port-forward -n $NAMESPACE svc/ytempire-backend 5000:5000"
    echo "  Delete:        kind delete cluster --name=$CLUSTER_NAME"
}

# Run tests
run_tests() {
    echo -e "\n${YELLOW}Running tests...${NC}"
    
    # Install test dependencies
    npm install --save-dev @kubernetes/client-node
    
    # Run Kubernetes tests
    npm run test:kubernetes || true
    
    echo -e "${GREEN}✓ Tests completed${NC}"
}

# Main execution
main() {
    check_prerequisites
    create_cluster
    install_ingress
    create_storage_dirs
    deploy_ytempire
    configure_hosts
    display_info
    
    # Ask if user wants to run tests
    read -p "Do you want to run tests? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_tests
    fi
}

# Run main function
main