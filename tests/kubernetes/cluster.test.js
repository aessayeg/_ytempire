/**
 * Kubernetes Cluster Tests
 * YTEmpire Project
 */

const k8s = require('@kubernetes/client-node');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

// Configure Kubernetes client
const kc = new k8s.KubeConfig();
kc.loadFromDefault();

const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
const k8sAppsApi = kc.makeApiClient(k8s.AppsV1Api);
const k8sNetworkingApi = kc.makeApiClient(k8s.NetworkingV1Api);

describe('Kubernetes Cluster Infrastructure', () => {
  const namespace = 'ytempire-dev';

  beforeAll(async () => {
    // Ensure cluster is running
    try {
      await execAsync('kubectl cluster-info');
    } catch (error) {
      throw new Error(
        'Kubernetes cluster is not accessible. Please ensure kind/minikube is running.'
      );
    }
  }, 30000);

  describe('Cluster Configuration', () => {
    test('Kubernetes cluster is accessible', async () => {
      const response = await k8sApi.listNode();
      expect(response.body.items.length).toBeGreaterThan(0);

      const nodes = response.body.items;
      nodes.forEach((node) => {
        expect(node.status.conditions.find((c) => c.type === 'Ready').status).toBe('True');
      });
    });

    test('Required nodes are available', async () => {
      const response = await k8sApi.listNode();
      const nodes = response.body.items;

      // Check for control plane and worker nodes
      const controlPlane = nodes.find(
        (n) => n.metadata.labels['node-role.kubernetes.io/control-plane'] !== undefined
      );
      expect(controlPlane).toBeDefined();

      // Verify node resources
      nodes.forEach((node) => {
        const allocatable = node.status.allocatable;
        expect(parseInt(allocatable.cpu)).toBeGreaterThanOrEqual(2);
        expect(parseInt(allocatable.memory.replace('Ki', '')) / 1024 / 1024).toBeGreaterThanOrEqual(
          2
        ); // At least 2GB
      });
    });

    test('Storage classes are configured correctly', async () => {
      const { stdout } = await execAsync('kubectl get storageclass -o json');
      const storageClasses = JSON.parse(stdout);

      const localStorage = storageClasses.items.find((sc) => sc.metadata.name === 'local-storage');
      expect(localStorage).toBeDefined();
      expect(localStorage.provisioner).toBe('kubernetes.io/no-provisioner');
      expect(localStorage.volumeBindingMode).toBe('WaitForFirstConsumer');
    });
  });

  describe('Namespaces', () => {
    test('All namespaces are created and accessible', async () => {
      const response = await k8sApi.listNamespace();
      const namespaces = response.body.items.map((ns) => ns.metadata.name);

      expect(namespaces).toContain('ytempire-dev');
      expect(namespaces).toContain('ytempire-monitoring');

      // Check namespace labels
      const ytempireNs = response.body.items.find((ns) => ns.metadata.name === 'ytempire-dev');
      expect(ytempireNs.metadata.labels.environment).toBe('development');
      expect(ytempireNs.metadata.labels.project).toBe('ytempire');
    });

    test('Resource quotas are applied', async () => {
      const response = await k8sApi.listNamespacedResourceQuota(namespace);
      expect(response.body.items.length).toBeGreaterThan(0);

      const quota = response.body.items[0];
      expect(quota.spec.hard['requests.cpu']).toBe('4');
      expect(quota.spec.hard['requests.memory']).toBe('8Gi');
    });

    test('Network policies are configured', async () => {
      const response = await k8sNetworkingApi.listNamespacedNetworkPolicy(namespace);
      expect(response.body.items.length).toBeGreaterThan(0);

      const policy = response.body.items.find(
        (p) => p.metadata.name === 'ytempire-dev-network-policy'
      );
      expect(policy).toBeDefined();
      expect(policy.spec.policyTypes).toContain('Ingress');
      expect(policy.spec.policyTypes).toContain('Egress');
    });
  });

  describe('Storage Configuration', () => {
    test('Persistent volumes are created and bound', async () => {
      const pvResponse = await k8sApi.listPersistentVolume();
      const pvs = pvResponse.body.items;

      const requiredPVs = ['postgresql-pv', 'redis-pv', 'uploads-pv', 'logs-pv'];
      requiredPVs.forEach((pvName) => {
        const pv = pvs.find((p) => p.metadata.name === pvName);
        expect(pv).toBeDefined();
        expect(['Available', 'Bound']).toContain(pv.status.phase);
      });
    });

    test('Persistent volume claims are bound', async () => {
      const pvcResponse = await k8sApi.listNamespacedPersistentVolumeClaim(namespace);
      const pvcs = pvcResponse.body.items;

      pvcs.forEach((pvc) => {
        expect(pvc.status.phase).toBe('Bound');
      });
    });

    test('Storage capacity meets requirements', async () => {
      const pvResponse = await k8sApi.listPersistentVolume();
      const pvs = pvResponse.body.items;

      const postgresqlPV = pvs.find((pv) => pv.metadata.name === 'postgresql-pv');
      expect(postgresqlPV.spec.capacity.storage).toBe('5Gi');

      const uploadsPV = pvs.find((pv) => pv.metadata.name === 'uploads-pv');
      expect(uploadsPV.spec.capacity.storage).toBe('10Gi');
    });
  });

  describe('ConfigMaps and Secrets', () => {
    test('All ConfigMaps are created', async () => {
      const response = await k8sApi.listNamespacedConfigMap(namespace);
      const configMaps = response.body.items.map((cm) => cm.metadata.name);

      expect(configMaps).toContain('ytempire-config');
      expect(configMaps).toContain('postgresql-config');
      expect(configMaps).toContain('redis-config');
      expect(configMaps).toContain('backend-config');
      expect(configMaps).toContain('frontend-config');
    });

    test('All Secrets are created', async () => {
      const response = await k8sApi.listNamespacedSecret(namespace);
      const secrets = response.body.items.map((s) => s.metadata.name);

      expect(secrets).toContain('postgresql-secret');
      expect(secrets).toContain('ytempire-secrets');
    });

    test('ConfigMap data is valid', async () => {
      const response = await k8sApi.readNamespacedConfigMap('ytempire-config', namespace);
      const config = response.body.data;

      expect(config.NODE_ENV).toBe('development');
      expect(config.LOG_LEVEL).toBe('debug');
      expect(config.API_BASE_URL).toBe('http://ytempire-backend:5000');
      expect(parseInt(config.MAX_FILE_SIZE)).toBe(104857600);
    });
  });

  describe('Ingress Controller', () => {
    test('Ingress controller is deployed', async () => {
      const { stdout } = await execAsync('kubectl get pods -n ingress-nginx -o json');
      const pods = JSON.parse(stdout);

      const controller = pods.items.find((p) =>
        p.metadata.name.includes('ingress-nginx-controller')
      );
      expect(controller).toBeDefined();
      expect(controller.status.phase).toBe('Running');
    });

    test('Ingress class is configured', async () => {
      const response = await k8sNetworkingApi.listIngressClass();
      const nginxClass = response.body.items.find((ic) => ic.metadata.name === 'nginx');

      expect(nginxClass).toBeDefined();
      expect(nginxClass.spec.controller).toBe('k8s.io/ingress-nginx');
    });

    test('Ingress rules are configured correctly', async () => {
      const response = await k8sNetworkingApi.listNamespacedIngress(namespace);
      const ingress = response.body.items.find((i) => i.metadata.name === 'ytempire-ingress');

      expect(ingress).toBeDefined();
      expect(ingress.spec.rules.length).toBeGreaterThan(0);

      const mainRule = ingress.spec.rules.find((r) => r.host === 'ytempire.local');
      expect(mainRule).toBeDefined();
      expect(mainRule.http.paths.length).toBeGreaterThan(0);
    });
  });

  describe('Service Accounts and RBAC', () => {
    test('Service accounts are created', async () => {
      const response = await k8sApi.listNamespacedServiceAccount(namespace);
      const serviceAccounts = response.body.items.map((sa) => sa.metadata.name);

      expect(serviceAccounts).toContain('ytempire-backend');
      expect(serviceAccounts).toContain('ytempire-frontend');
    });

    test('Service account tokens exist', async () => {
      const response = await k8sApi.listNamespacedSecret(namespace);
      const saTokens = response.body.items.filter(
        (s) => s.type === 'kubernetes.io/service-account-token'
      );

      expect(saTokens.length).toBeGreaterThan(0);
    });
  });
});
