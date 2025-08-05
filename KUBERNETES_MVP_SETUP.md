# YTEmpire Kubernetes MVP Setup Guide

## Overview

This guide provides comprehensive instructions for setting up the YTEmpire MVP on a local Kubernetes cluster using kind (Kubernetes in Docker). The setup is optimized for local development with no external cloud dependencies.

## Architecture

The YTEmpire Kubernetes deployment consists of:

- **Frontend**: Next.js application (2 replicas with HPA)
- **Backend**: Express API server (2 replicas with HPA)
- **PostgreSQL**: Primary database (StatefulSet)
- **Redis**: Caching and sessions (StatefulSet)
- **pgAdmin**: Database management UI
- **MailHog**: Local email testing
- **Nginx Ingress**: Traffic routing

## Prerequisites

1. **Docker Desktop** installed and running
2. **8GB RAM** minimum (16GB recommended)
3. **20GB free disk space**
4. **Linux/macOS** (Windows via WSL2)

## Quick Start

### 1. Install Required Tools

```bash
# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install helm (optional)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 2. Create Kubernetes Cluster

```bash
# Create kind cluster with custom configuration
kind create cluster --config=kind-config.yaml --name=ytempire-dev

# Verify cluster is running
kubectl cluster-info
```

### 3. Install Ingress Controller

```bash
# Install NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s
```

### 4. Create Storage Directories

```bash
# Create local directories for persistent volumes
mkdir -p k8s-data/{postgresql,redis,logs}
mkdir -p uploads
```

### 5. Deploy YTEmpire

```bash
# Using kubectl with kustomize
kubectl apply -k kubernetes/base/

# Or using individual manifests
kubectl apply -f kubernetes/base/namespace.yaml
kubectl apply -f kubernetes/base/storage.yaml
kubectl apply -f kubernetes/base/secrets.yaml
kubectl apply -f kubernetes/base/configmap.yaml
kubectl apply -f kubernetes/base/postgresql.yaml
kubectl apply -f kubernetes/base/redis.yaml
kubectl apply -f kubernetes/base/backend.yaml
kubectl apply -f kubernetes/base/frontend.yaml
kubectl apply -f kubernetes/base/ingress.yaml
```

### 6. Configure Local DNS

Add to `/etc/hosts`:

```
127.0.0.1 ytempire.local api.ytempire.local pgadmin.ytempire.local mailhog.ytempire.local
```

### 7. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n ytempire-dev

# Check services
kubectl get svc -n ytempire-dev

# Check ingress
kubectl get ingress -n ytempire-dev
```

## Access Points

### Web Interfaces

- **Application**: http://ytempire.local
- **API Documentation**: http://api.ytempire.local/docs
- **pgAdmin**: http://pgadmin.ytempire.local
  - Email: admin@ytempire.local
  - Password: admin123
- **MailHog**: http://mailhog.ytempire.local

### Direct NodePort Access

- **PostgreSQL**: localhost:30000
  - User: ytempire_user
  - Password: ytempire_pass
  - Database: ytempire_dev
- **Redis**: localhost:30001
- **pgAdmin**: localhost:30002
- **MailHog**: localhost:30003

## Development Workflow

### Viewing Logs

```bash
# Backend logs
kubectl logs -n ytempire-dev -l app=ytempire-backend -f

# Frontend logs
kubectl logs -n ytempire-dev -l app=ytempire-frontend -f

# PostgreSQL logs
kubectl logs -n ytempire-dev -l app=postgresql -f
```

### Executing Commands

```bash
# Access PostgreSQL
kubectl exec -it -n ytempire-dev postgresql-0 -- psql -U ytempire_user -d ytempire_dev

# Access Redis
kubectl exec -it -n ytempire-dev redis-0 -- redis-cli

# Access backend shell
kubectl exec -it -n ytempire-dev deployment/ytempire-backend -- sh
```

### Port Forwarding

```bash
# Forward backend API
kubectl port-forward -n ytempire-dev svc/ytempire-backend 5000:5000

# Forward PostgreSQL
kubectl port-forward -n ytempire-dev svc/postgresql 5432:5432
```

### Scaling Applications

```bash
# Manual scaling
kubectl scale -n ytempire-dev deployment/ytempire-backend --replicas=3

# Check HPA status
kubectl get hpa -n ytempire-dev
```

## Storage Management

### Persistent Volumes

The setup uses local persistent volumes:

- **PostgreSQL**: 5Gi at `/data/postgresql`
- **Redis**: 2Gi at `/data/redis`
- **Uploads**: 10Gi at `/uploads`
- **Logs**: 5Gi at `/data/logs`

### Backup and Restore

```bash
# Backup PostgreSQL
kubectl exec -n ytempire-dev postgresql-0 -- pg_dump -U ytempire_user ytempire_dev > backup.sql

# Restore PostgreSQL
kubectl exec -i -n ytempire-dev postgresql-0 -- psql -U ytempire_user ytempire_dev < backup.sql
```

## Monitoring

### Resource Usage

```bash
# View node resources
kubectl top nodes

# View pod resources
kubectl top pods -n ytempire-dev

# View detailed pod metrics
kubectl describe pod -n ytempire-dev <pod-name>
```

### Health Checks

```bash
# Check backend health
curl http://ytempire.local/api/health

# Check frontend health
curl http://ytempire.local/api/health

# Check database connection
kubectl exec -n ytempire-dev deployment/ytempire-backend -- nc -zv postgresql 5432
```

## Testing

### Run Kubernetes Tests

```bash
# Install test dependencies
npm install --save-dev @kubernetes/client-node jest

# Run all tests
npm run test:kubernetes

# Run specific test suite
npm run test:kubernetes -- tests/kubernetes/cluster.test.js
```

### Test Categories

1. **Cluster Tests**: Infrastructure validation
2. **Deployment Tests**: Pod health and readiness
3. **Service Tests**: Connectivity and discovery
4. **Storage Tests**: Persistence and performance
5. **Integration Tests**: End-to-end functionality

## Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
# Check pod events
kubectl describe pod -n ytempire-dev <pod-name>

# Check pod logs
kubectl logs -n ytempire-dev <pod-name> --previous
```

#### Storage Issues

```bash
# Check PV status
kubectl get pv

# Check PVC status
kubectl get pvc -n ytempire-dev

# Check mount points
kubectl exec -n ytempire-dev <pod-name> -- df -h
```

#### Network Issues

```bash
# Check service endpoints
kubectl get endpoints -n ytempire-dev

# Test DNS resolution
kubectl exec -n ytempire-dev deployment/ytempire-backend -- nslookup postgresql

# Check ingress
kubectl describe ingress -n ytempire-dev ytempire-ingress
```

### Reset Environment

```bash
# Delete all resources
kubectl delete namespace ytempire-dev

# Delete cluster
kind delete cluster --name=ytempire-dev

# Clean storage
rm -rf k8s-data uploads
```

## Using Helm (Optional)

### Install with Helm

```bash
# Add helm dependencies
helm dependency update ./helm/ytempire

# Install
helm install ytempire ./helm/ytempire -n ytempire-dev --create-namespace

# Upgrade
helm upgrade ytempire ./helm/ytempire -n ytempire-dev

# Uninstall
helm uninstall ytempire -n ytempire-dev
```

### Custom Values

Create `values-local.yaml`:

```yaml
frontend:
  replicaCount: 1

backend:
  replicaCount: 1

postgresql:
  auth:
    password: your-secure-password

ingress:
  hosts:
    - host: my-ytempire.local
```

Install with custom values:

```bash
helm install ytempire ./helm/ytempire -f values-local.yaml
```

## Security Considerations

1. **Secrets Management**: Use Sealed Secrets or External Secrets in production
2. **Network Policies**: Implemented to restrict pod communication
3. **RBAC**: Service accounts with minimal permissions
4. **Pod Security**: Non-root containers with security contexts
5. **Resource Limits**: Prevent resource exhaustion

## Performance Optimization

1. **Resource Requests/Limits**: Properly sized for MVP workload
2. **HPA**: Automatic scaling based on CPU/memory
3. **Persistent Storage**: Local SSDs recommended
4. **Node Affinity**: Distribute pods across nodes
5. **Init Containers**: Ensure dependencies are ready

## Next Steps

1. **Add Monitoring**: Deploy Prometheus and Grafana
2. **Add Logging**: Deploy ELK or Loki stack
3. **Add Service Mesh**: Install Istio or Linkerd
4. **Add CI/CD**: Integrate with GitOps (ArgoCD/Flux)
5. **Production Ready**: Move to managed Kubernetes

## Support

For issues:

1. Check pod logs and events
2. Run the test suite
3. Check the troubleshooting section
4. Review Kubernetes documentation
5. Open an issue with detailed logs

---

**Note**: This MVP setup uses local storage and is designed for development. For production, use cloud storage, managed databases, and proper secret management.
