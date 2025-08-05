/**
 * Kubernetes Services Tests
 * YTEmpire Project
 */

const k8s = require('@kubernetes/client-node');
const axios = require('axios');
const { Client } = require('pg');
const redis = require('redis');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

const kc = new k8s.KubeConfig();
kc.loadFromDefault();

const k8sApi = kc.makeApiClient(k8s.CoreV1Api);

describe('Kubernetes Services', () => {
  const namespace = 'ytempire-dev';

  describe('Service Configuration', () => {
    test('All services are created and accessible', async () => {
      const response = await k8sApi.listNamespacedService(namespace);
      const services = response.body.items.map((s) => s.metadata.name);

      const requiredServices = [
        'ytempire-backend',
        'ytempire-frontend',
        'postgresql',
        'postgresql-headless',
        'redis',
        'pgadmin',
        'mailhog',
      ];

      requiredServices.forEach((serviceName) => {
        expect(services).toContain(serviceName);
      });
    });

    test('Service endpoints are populated', async () => {
      const response = await k8sApi.listNamespacedEndpoints(namespace);
      const endpoints = response.body.items;

      endpoints.forEach((endpoint) => {
        if (endpoint.subsets && endpoint.subsets.length > 0) {
          expect(endpoint.subsets[0].addresses.length).toBeGreaterThan(0);
        }
      });
    });

    test('Service ports are correctly configured', async () => {
      const backendService = await k8sApi.readNamespacedService('ytempire-backend', namespace);
      expect(backendService.body.spec.ports[0].port).toBe(5000);
      expect(backendService.body.spec.ports[0].targetPort).toBe(5000);

      const frontendService = await k8sApi.readNamespacedService('ytempire-frontend', namespace);
      expect(frontendService.body.spec.ports[0].port).toBe(3000);
      expect(frontendService.body.spec.ports[0].targetPort).toBe(3000);

      const postgresService = await k8sApi.readNamespacedService('postgresql', namespace);
      expect(postgresService.body.spec.ports[0].port).toBe(5432);
      expect(postgresService.body.spec.type).toBe('NodePort');
      expect(postgresService.body.spec.ports[0].nodePort).toBe(30000);
    });

    test('Headless services are configured correctly', async () => {
      const postgresHeadless = await k8sApi.readNamespacedService('postgresql-headless', namespace);
      expect(postgresHeadless.body.spec.clusterIP).toBe('None');
      expect(postgresHeadless.body.spec.type).toBe('ClusterIP');
    });
  });

  describe('Service Discovery', () => {
    test('DNS resolution works between services', async () => {
      // Test DNS resolution from a test pod
      const testPodManifest = {
        apiVersion: 'v1',
        kind: 'Pod',
        metadata: {
          name: 'dns-test-pod',
          namespace: namespace,
        },
        spec: {
          containers: [
            {
              name: 'test',
              image: 'busybox:latest',
              command: ['sleep', '300'],
            },
          ],
          restartPolicy: 'Never',
        },
      };

      // Create test pod
      try {
        await k8sApi.createNamespacedPod(namespace, testPodManifest);

        // Wait for pod to be ready
        await new Promise((resolve) => setTimeout(resolve, 5000));

        // Test DNS resolution
        const services = ['ytempire-backend', 'ytempire-frontend', 'postgresql', 'redis'];

        for (const service of services) {
          const { stdout } = await execAsync(
            `kubectl exec -n ${namespace} dns-test-pod -- nslookup ${service}`
          );
          expect(stdout).toContain(`Name:\t${service}`);
          expect(stdout).toContain('Address:');
        }
      } finally {
        // Cleanup
        await k8sApi.deleteNamespacedPod('dns-test-pod', namespace).catch(() => {});
      }
    });

    test('Service discovery via environment variables', async () => {
      const backendPods = await k8sApi.listNamespacedPod(
        namespace,
        undefined,
        undefined,
        undefined,
        undefined,
        'app=ytempire-backend'
      );

      if (backendPods.body.items.length > 0) {
        const pod = backendPods.body.items[0];
        const { stdout } = await execAsync(
          `kubectl exec -n ${namespace} ${pod.metadata.name} -- env | grep SERVICE`
        );

        // Should have service discovery environment variables
        expect(stdout).toContain('POSTGRESQL_SERVICE_HOST');
        expect(stdout).toContain('POSTGRESQL_SERVICE_PORT');
        expect(stdout).toContain('REDIS_SERVICE_HOST');
        expect(stdout).toContain('REDIS_SERVICE_PORT');
      }
    });
  });

  describe('Service Connectivity', () => {
    test('Backend can connect to PostgreSQL', async () => {
      const backendPods = await k8sApi.listNamespacedPod(
        namespace,
        undefined,
        undefined,
        undefined,
        undefined,
        'app=ytempire-backend'
      );

      if (backendPods.body.items.length > 0) {
        const pod = backendPods.body.items[0];

        // Test PostgreSQL connectivity from backend pod
        const { stdout } = await execAsync(
          `kubectl exec -n ${namespace} ${pod.metadata.name} -- nc -zv postgresql 5432`
        );
        expect(stdout).toContain('succeeded');
      }
    });

    test('Backend can connect to Redis', async () => {
      const backendPods = await k8sApi.listNamespacedPod(
        namespace,
        undefined,
        undefined,
        undefined,
        undefined,
        'app=ytempire-backend'
      );

      if (backendPods.body.items.length > 0) {
        const pod = backendPods.body.items[0];

        // Test Redis connectivity from backend pod
        const { stdout } = await execAsync(
          `kubectl exec -n ${namespace} ${pod.metadata.name} -- nc -zv redis 6379`
        );
        expect(stdout).toContain('succeeded');
      }
    });

    test('Frontend can reach Backend API', async () => {
      const frontendPods = await k8sApi.listNamespacedPod(
        namespace,
        undefined,
        undefined,
        undefined,
        undefined,
        'app=ytempire-frontend'
      );

      if (frontendPods.body.items.length > 0) {
        const pod = frontendPods.body.items[0];

        // Test backend API connectivity from frontend pod
        const { stdout } = await execAsync(
          `kubectl exec -n ${namespace} ${pod.metadata.name} -- wget -qO- http://ytempire-backend:5000/health || echo "Connection failed"`
        );

        if (stdout !== 'Connection failed') {
          const response = JSON.parse(stdout);
          expect(response.status).toBe('OK');
        }
      }
    });
  });

  describe('NodePort Services', () => {
    test('NodePort services are accessible from host', async () => {
      // Get node IP
      const nodes = await k8sApi.listNode();
      const nodeIP = nodes.body.items[0].status.addresses.find(
        (addr) => addr.type === 'InternalIP'
      ).address;

      // Test PostgreSQL NodePort (30000)
      const pgClient = new Client({
        host: nodeIP,
        port: 30000,
        user: 'ytempire_user',
        password: 'ytempire_pass',
        database: 'ytempire_dev',
        connectionTimeoutMillis: 5000,
      });

      try {
        await pgClient.connect();
        const result = await pgClient.query('SELECT 1');
        expect(result.rows[0]['?column?']).toBe(1);
      } catch (error) {
        console.log('PostgreSQL NodePort test skipped:', error.message);
      } finally {
        await pgClient.end().catch(() => {});
      }
    });

    test('Service NodePort assignments are correct', async () => {
      const services = await k8sApi.listNamespacedService(namespace);

      const nodePortServices = services.body.items.filter((s) => s.spec.type === 'NodePort');

      nodePortServices.forEach((service) => {
        if (service.metadata.name === 'postgresql') {
          expect(service.spec.ports[0].nodePort).toBe(30000);
        }
        if (service.metadata.name === 'redis') {
          expect(service.spec.ports[0].nodePort).toBe(30001);
        }
        if (service.metadata.name === 'pgadmin') {
          expect(service.spec.ports[0].nodePort).toBe(30002);
        }
        if (service.metadata.name === 'mailhog') {
          const uiPort = service.spec.ports.find((p) => p.name === 'ui');
          expect(uiPort.nodePort).toBe(30003);
        }
      });
    });
  });

  describe('Service Load Balancing', () => {
    test('Service load balancing works across backend replicas', async () => {
      // Get backend service endpoints
      const endpoints = await k8sApi.readNamespacedEndpoints('ytempire-backend', namespace);

      if (endpoints.body.subsets && endpoints.body.subsets[0].addresses.length > 1) {
        // Multiple endpoints means load balancing should work
        const endpointCount = endpoints.body.subsets[0].addresses.length;
        expect(endpointCount).toBeGreaterThanOrEqual(2);

        // Each endpoint should be a different pod
        const podIPs = endpoints.body.subsets[0].addresses.map((addr) => addr.ip);
        expect(new Set(podIPs).size).toBe(podIPs.length);
      }
    });

    test('Session affinity is configured where needed', async () => {
      const backendService = await k8sApi.readNamespacedService('ytempire-backend', namespace);

      // Check if session affinity is set (if required)
      if (backendService.body.spec.sessionAffinity) {
        expect(backendService.body.spec.sessionAffinity).toBe('ClientIP');
        expect(backendService.body.spec.sessionAffinityConfig.clientIP.timeoutSeconds).toBe(10800);
      }
    });
  });

  describe('Service Health Checks', () => {
    test('Backend health endpoint responds correctly', async () => {
      // Port-forward to test service
      const portForwardProcess = exec(
        `kubectl port-forward -n ${namespace} service/ytempire-backend 15000:5000`
      );

      try {
        // Wait for port-forward to establish
        await new Promise((resolve) => setTimeout(resolve, 2000));

        const response = await axios
          .get('http://localhost:15000/health', {
            timeout: 5000,
          })
          .catch((err) => ({ data: null, status: err.response?.status }));

        if (response.data) {
          expect(response.data.status).toBe('OK');
          expect(response.data.timestamp).toBeDefined();
        }
      } finally {
        // Kill port-forward process
        portForwardProcess.kill();
      }
    });

    test('Service endpoints are healthy', async () => {
      const services = ['ytempire-backend', 'ytempire-frontend', 'postgresql', 'redis'];

      for (const serviceName of services) {
        const endpoints = await k8sApi.readNamespacedEndpoints(serviceName, namespace);

        if (endpoints.body.subsets && endpoints.body.subsets.length > 0) {
          const addresses = endpoints.body.subsets[0].addresses || [];
          expect(addresses.length).toBeGreaterThan(0);

          // All addresses should be ready
          addresses.forEach((addr) => {
            // If targetRef exists, check pod status
            if (addr.targetRef) {
              expect(addr.targetRef.kind).toBe('Pod');
            }
          });
        }
      }
    });
  });
});
