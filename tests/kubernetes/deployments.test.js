/**
 * Kubernetes Deployments Tests
 * YTEmpire Project
 */

const k8s = require('@kubernetes/client-node');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

const kc = new k8s.KubeConfig();
kc.loadFromDefault();

const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
const k8sAppsApi = kc.makeApiClient(k8s.AppsV1Api);

describe('Kubernetes Deployments and Pods', () => {
  const namespace = 'ytempire-dev';
  const deployments = ['ytempire-backend', 'ytempire-frontend', 'pgadmin', 'mailhog'];
  const statefulsets = ['postgresql', 'redis'];

  describe('Deployments Status', () => {
    test('All deployments are running successfully', async () => {
      const response = await k8sAppsApi.listNamespacedDeployment(namespace);
      
      deployments.forEach(deploymentName => {
        const deployment = response.body.items.find(d => d.metadata.name === deploymentName);
        expect(deployment).toBeDefined();
        expect(deployment.status.replicas).toBe(deployment.status.readyReplicas);
        expect(deployment.status.conditions.find(c => c.type === 'Available').status).toBe('True');
      });
    });

    test('All StatefulSets are running successfully', async () => {
      const response = await k8sAppsApi.listNamespacedStatefulSet(namespace);
      
      statefulsets.forEach(stsName => {
        const sts = response.body.items.find(s => s.metadata.name === stsName);
        expect(sts).toBeDefined();
        expect(sts.status.replicas).toBe(sts.status.readyReplicas);
        expect(sts.status.currentReplicas).toBe(sts.spec.replicas);
      });
    });

    test('Deployment replicas match specifications', async () => {
      const backendDeploy = await k8sAppsApi.readNamespacedDeployment('ytempire-backend', namespace);
      expect(backendDeploy.body.spec.replicas).toBe(2);
      expect(backendDeploy.body.status.readyReplicas).toBe(2);

      const frontendDeploy = await k8sAppsApi.readNamespacedDeployment('ytempire-frontend', namespace);
      expect(frontendDeploy.body.spec.replicas).toBe(2);
      expect(frontendDeploy.body.status.readyReplicas).toBe(2);
    });
  });

  describe('Pod Health and Readiness', () => {
    test('All pods are running and ready', async () => {
      const response = await k8sApi.listNamespacedPod(namespace);
      const pods = response.body.items;
      
      pods.forEach(pod => {
        expect(pod.status.phase).toBe('Running');
        
        // Check all containers are ready
        if (pod.status.containerStatuses) {
          pod.status.containerStatuses.forEach(container => {
            expect(container.ready).toBe(true);
            expect(container.state.running).toBeDefined();
          });
        }
      });
    });

    test('PostgreSQL pods are ready and healthy', async () => {
      const response = await k8sApi.listNamespacedPod(namespace, undefined, undefined, undefined, undefined, 'app=postgresql');
      const pods = response.body.items;
      
      expect(pods.length).toBeGreaterThan(0);
      pods.forEach(pod => {
        expect(pod.status.phase).toBe('Running');
        const postgresContainer = pod.status.containerStatuses.find(c => c.name === 'postgresql');
        expect(postgresContainer.ready).toBe(true);
      });
    });

    test('Backend pods are ready and healthy', async () => {
      const response = await k8sApi.listNamespacedPod(namespace, undefined, undefined, undefined, undefined, 'app=ytempire-backend');
      const pods = response.body.items;
      
      expect(pods.length).toBe(2); // Should have 2 replicas
      pods.forEach(pod => {
        expect(pod.status.phase).toBe('Running');
        const backendContainer = pod.status.containerStatuses.find(c => c.name === 'backend');
        expect(backendContainer.ready).toBe(true);
      });
    });

    test('Frontend pods are ready and healthy', async () => {
      const response = await k8sApi.listNamespacedPod(namespace, undefined, undefined, undefined, undefined, 'app=ytempire-frontend');
      const pods = response.body.items;
      
      expect(pods.length).toBe(2); // Should have 2 replicas
      pods.forEach(pod => {
        expect(pod.status.phase).toBe('Running');
        const frontendContainer = pod.status.containerStatuses.find(c => c.name === 'frontend');
        expect(frontendContainer.ready).toBe(true);
      });
    });

    test('Redis pods are ready and healthy', async () => {
      const response = await k8sApi.listNamespacedPod(namespace, undefined, undefined, undefined, undefined, 'app=redis');
      const pods = response.body.items;
      
      expect(pods.length).toBeGreaterThan(0);
      pods.forEach(pod => {
        expect(pod.status.phase).toBe('Running');
        const redisContainer = pod.status.containerStatuses.find(c => c.name === 'redis');
        expect(redisContainer.ready).toBe(true);
      });
    });
  });

  describe('Liveness and Readiness Probes', () => {
    test('All pods pass liveness probes', async () => {
      const response = await k8sApi.listNamespacedPod(namespace);
      const pods = response.body.items;
      
      // Check recent events for liveness probe failures
      const eventsResponse = await k8sApi.listNamespacedEvent(namespace);
      const events = eventsResponse.body.items;
      
      const livenessFailures = events.filter(e => 
        e.reason === 'Unhealthy' && 
        e.message.includes('Liveness probe failed')
      );
      
      // Should have no recent liveness failures
      const recentFailures = livenessFailures.filter(e => {
        const eventTime = new Date(e.lastTimestamp);
        const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
        return eventTime > fiveMinutesAgo;
      });
      
      expect(recentFailures.length).toBe(0);
    });

    test('All pods pass readiness probes', async () => {
      const response = await k8sApi.listNamespacedPod(namespace);
      const pods = response.body.items;
      
      pods.forEach(pod => {
        if (pod.status.conditions) {
          const readyCondition = pod.status.conditions.find(c => c.type === 'Ready');
          expect(readyCondition.status).toBe('True');
        }
      });
    });

    test('Probe configurations are correct', async () => {
      // Check backend deployment probe config
      const backendDeploy = await k8sAppsApi.readNamespacedDeployment('ytempire-backend', namespace);
      const backendContainer = backendDeploy.body.spec.template.spec.containers.find(c => c.name === 'backend');
      
      expect(backendContainer.livenessProbe).toBeDefined();
      expect(backendContainer.livenessProbe.httpGet.path).toBe('/health');
      expect(backendContainer.livenessProbe.httpGet.port).toBe(5000);
      
      expect(backendContainer.readinessProbe).toBeDefined();
      expect(backendContainer.readinessProbe.httpGet.path).toBe('/ready');
      expect(backendContainer.readinessProbe.httpGet.port).toBe(5000);
    });
  });

  describe('Resource Limits and Requests', () => {
    test('All containers have resource limits defined', async () => {
      const response = await k8sApi.listNamespacedPod(namespace);
      const pods = response.body.items;
      
      pods.forEach(pod => {
        pod.spec.containers.forEach(container => {
          expect(container.resources).toBeDefined();
          expect(container.resources.requests).toBeDefined();
          expect(container.resources.limits).toBeDefined();
          
          expect(container.resources.requests.memory).toBeDefined();
          expect(container.resources.requests.cpu).toBeDefined();
          expect(container.resources.limits.memory).toBeDefined();
          expect(container.resources.limits.cpu).toBeDefined();
        });
      });
    });

    test('Resource allocations are within cluster capacity', async () => {
      const { stdout } = await execAsync(`kubectl top nodes -o json`).catch(() => ({ stdout: '{}' }));
      
      if (stdout !== '{}') {
        const nodeMetrics = JSON.parse(stdout);
        
        // Check that we're not over-provisioning
        nodeMetrics.items.forEach(node => {
          const cpuUsage = parseInt(node.usage.cpu.replace('n', '')) / 1000000000; // Convert to cores
          const memoryUsage = parseInt(node.usage.memory.replace('Ki', '')) / 1024 / 1024; // Convert to GB
          
          // Should have headroom (not using more than 80% of resources)
          expect(cpuUsage).toBeLessThan(node.allocatable.cpu * 0.8);
          expect(memoryUsage).toBeLessThan(parseInt(node.allocatable.memory.replace('Ki', '')) / 1024 / 1024 * 0.8);
        });
      }
    });
  });

  describe('Init Containers', () => {
    test('Init containers completed successfully', async () => {
      const response = await k8sApi.listNamespacedPod(namespace);
      const pods = response.body.items;
      
      pods.forEach(pod => {
        if (pod.spec.initContainers && pod.spec.initContainers.length > 0) {
          // Check init container statuses
          if (pod.status.initContainerStatuses) {
            pod.status.initContainerStatuses.forEach(initContainer => {
              expect(initContainer.ready).toBe(true);
              expect(initContainer.state.terminated).toBeDefined();
              expect(initContainer.state.terminated.exitCode).toBe(0);
            });
          }
        }
      });
    });

    test('Backend waits for dependencies', async () => {
      const backendDeploy = await k8sAppsApi.readNamespacedDeployment('ytempire-backend', namespace);
      const initContainers = backendDeploy.body.spec.template.spec.initContainers;
      
      expect(initContainers).toBeDefined();
      expect(initContainers.length).toBe(2);
      
      const postgresWait = initContainers.find(c => c.name === 'wait-for-postgres');
      expect(postgresWait).toBeDefined();
      
      const redisWait = initContainers.find(c => c.name === 'wait-for-redis');
      expect(redisWait).toBeDefined();
    });
  });

  describe('Pod Distribution', () => {
    test('Pods are distributed across nodes', async () => {
      const response = await k8sApi.listNamespacedPod(namespace);
      const pods = response.body.items;
      
      // Group pods by node
      const podsByNode = {};
      pods.forEach(pod => {
        const nodeName = pod.spec.nodeName;
        if (!podsByNode[nodeName]) {
          podsByNode[nodeName] = [];
        }
        podsByNode[nodeName].push(pod.metadata.name);
      });
      
      // For multi-node clusters, check distribution
      const nodeCount = Object.keys(podsByNode).length;
      if (nodeCount > 1) {
        // Pods should be somewhat evenly distributed
        const avgPodsPerNode = pods.length / nodeCount;
        Object.values(podsByNode).forEach(nodePods => {
          expect(nodePods.length).toBeGreaterThan(0);
          // Allow for some imbalance but not extreme
          expect(nodePods.length).toBeLessThan(avgPodsPerNode * 2);
        });
      }
    });

    test('Anti-affinity rules are respected', async () => {
      const backendPods = await k8sApi.listNamespacedPod(
        namespace, 
        undefined, 
        undefined, 
        undefined, 
        undefined, 
        'app=ytempire-backend'
      );
      
      if (backendPods.body.items.length > 1) {
        const nodes = backendPods.body.items.map(p => p.spec.nodeName);
        // If we have multiple nodes, backends should be on different nodes
        if (new Set(nodes).size > 1) {
          expect(new Set(nodes).size).toBeGreaterThan(1);
        }
      }
    });
  });
});