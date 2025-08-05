/**
 * Kubernetes Storage Tests
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

describe('Kubernetes Storage Configuration', () => {
  const namespace = 'ytempire-dev';

  describe('Persistent Volumes', () => {
    test('All required persistent volumes are created', async () => {
      const response = await k8sApi.listPersistentVolume();
      const pvs = response.body.items;

      const requiredPVs = [
        { name: 'postgresql-pv', capacity: '5Gi' },
        { name: 'redis-pv', capacity: '2Gi' },
        { name: 'uploads-pv', capacity: '10Gi' },
        { name: 'logs-pv', capacity: '5Gi' },
      ];

      requiredPVs.forEach((required) => {
        const pv = pvs.find((p) => p.metadata.name === required.name);
        expect(pv).toBeDefined();
        expect(pv.spec.capacity.storage).toBe(required.capacity);
        expect(['Available', 'Bound']).toContain(pv.status.phase);
      });
    });

    test('Persistent volumes have correct access modes', async () => {
      const response = await k8sApi.listPersistentVolume();
      const pvs = response.body.items;

      // PostgreSQL and Redis should be ReadWriteOnce
      const postgresqlPV = pvs.find((pv) => pv.metadata.name === 'postgresql-pv');
      expect(postgresqlPV.spec.accessModes).toContain('ReadWriteOnce');

      const redisPV = pvs.find((pv) => pv.metadata.name === 'redis-pv');
      expect(redisPV.spec.accessModes).toContain('ReadWriteOnce');

      // Uploads should be ReadWriteMany for shared access
      const uploadsPV = pvs.find((pv) => pv.metadata.name === 'uploads-pv');
      expect(uploadsPV.spec.accessModes).toContain('ReadWriteMany');
    });

    test('Host paths are correctly configured', async () => {
      const response = await k8sApi.listPersistentVolume();
      const pvs = response.body.items;

      pvs.forEach((pv) => {
        if (pv.spec.hostPath) {
          expect(pv.spec.hostPath.path).toBeDefined();
          expect(pv.spec.hostPath.type).toBe('DirectoryOrCreate');
        }
      });
    });
  });

  describe('Persistent Volume Claims', () => {
    test('All PVCs are bound to PVs', async () => {
      const response = await k8sApi.listNamespacedPersistentVolumeClaim(namespace);
      const pvcs = response.body.items;

      pvcs.forEach((pvc) => {
        expect(pvc.status.phase).toBe('Bound');
        expect(pvc.spec.volumeName).toBeDefined();
      });
    });

    test('PVC storage requests are satisfied', async () => {
      const response = await k8sApi.listNamespacedPersistentVolumeClaim(namespace);
      const pvcs = response.body.items;

      pvcs.forEach((pvc) => {
        const requested = pvc.spec.resources.requests.storage;
        const capacity = pvc.status.capacity?.storage;

        if (capacity) {
          // Capacity should be at least what was requested
          const requestedBytes = parseInt(requested.replace(/\D/g, ''));
          const capacityBytes = parseInt(capacity.replace(/\D/g, ''));
          expect(capacityBytes).toBeGreaterThanOrEqual(requestedBytes);
        }
      });
    });

    test('StatefulSet volume claims are created', async () => {
      // Check PostgreSQL volume claim
      const postgresqlSts = await k8sAppsApi.readNamespacedStatefulSet('postgresql', namespace);
      expect(postgresqlSts.body.spec.volumeClaimTemplates).toBeDefined();
      expect(postgresqlSts.body.spec.volumeClaimTemplates.length).toBe(1);

      // Check Redis volume claim
      const redisSts = await k8sAppsApi.readNamespacedStatefulSet('redis', namespace);
      expect(redisSts.body.spec.volumeClaimTemplates).toBeDefined();
      expect(redisSts.body.spec.volumeClaimTemplates.length).toBe(1);
    });
  });

  describe('Volume Mounts', () => {
    test('Backend pods have correct volume mounts', async () => {
      const deployment = await k8sAppsApi.readNamespacedDeployment('ytempire-backend', namespace);
      const container = deployment.body.spec.template.spec.containers.find(
        (c) => c.name === 'backend'
      );

      expect(container.volumeMounts).toBeDefined();

      const uploadMount = container.volumeMounts.find((vm) => vm.name === 'uploads');
      expect(uploadMount).toBeDefined();
      expect(uploadMount.mountPath).toBe('/app/uploads');

      const logsMount = container.volumeMounts.find((vm) => vm.name === 'logs');
      expect(logsMount).toBeDefined();
      expect(logsMount.mountPath).toBe('/app/logs');
    });

    test('PostgreSQL has data volume mounted', async () => {
      const sts = await k8sAppsApi.readNamespacedStatefulSet('postgresql', namespace);
      const container = sts.body.spec.template.spec.containers.find((c) => c.name === 'postgresql');

      const dataMount = container.volumeMounts.find((vm) => vm.name === 'postgresql-storage');
      expect(dataMount).toBeDefined();
      expect(dataMount.mountPath).toBe('/var/lib/postgresql/data');
    });

    test('Redis has data volume mounted', async () => {
      const sts = await k8sAppsApi.readNamespacedStatefulSet('redis', namespace);
      const container = sts.body.spec.template.spec.containers.find((c) => c.name === 'redis');

      const dataMount = container.volumeMounts.find((vm) => vm.name === 'redis-data');
      expect(dataMount).toBeDefined();
      expect(dataMount.mountPath).toBe('/data');
    });
  });

  describe('Data Persistence', () => {
    test('PostgreSQL data persists across pod restarts', async () => {
      // Get PostgreSQL pod
      const pods = await k8sApi.listNamespacedPod(
        namespace,
        undefined,
        undefined,
        undefined,
        undefined,
        'app=postgresql'
      );

      if (pods.body.items.length > 0) {
        const pod = pods.body.items[0];

        // Create test data
        await execAsync(
          `kubectl exec -n ${namespace} ${pod.metadata.name} -- psql -U ytempire_user -d ytempire_dev -c "CREATE TABLE IF NOT EXISTS persistence_test (id SERIAL PRIMARY KEY, data TEXT)"`
        );

        await execAsync(
          `kubectl exec -n ${namespace} ${
            pod.metadata.name
          } -- psql -U ytempire_user -d ytempire_dev -c "INSERT INTO persistence_test (data) VALUES ('test-data-${Date.now()}')"`
        );

        // Get data count before restart
        const { stdout: beforeCount } = await execAsync(
          `kubectl exec -n ${namespace} ${pod.metadata.name} -- psql -U ytempire_user -d ytempire_dev -t -c "SELECT COUNT(*) FROM persistence_test"`
        );

        // Delete pod to force restart
        await k8sApi.deleteNamespacedPod(pod.metadata.name, namespace);

        // Wait for new pod to be ready
        await new Promise((resolve) => setTimeout(resolve, 30000));

        // Get new pod
        const newPods = await k8sApi.listNamespacedPod(
          namespace,
          undefined,
          undefined,
          undefined,
          undefined,
          'app=postgresql'
        );

        if (newPods.body.items.length > 0) {
          const newPod = newPods.body.items[0];

          // Check data still exists
          const { stdout: afterCount } = await execAsync(
            `kubectl exec -n ${namespace} ${newPod.metadata.name} -- psql -U ytempire_user -d ytempire_dev -t -c "SELECT COUNT(*) FROM persistence_test"`
          );

          expect(parseInt(afterCount.trim())).toBe(parseInt(beforeCount.trim()));
        }
      }
    }, 60000);

    test('Uploaded files persist across deployments', async () => {
      // Create test file in uploads volume
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
        const testFile = `test-${Date.now()}.txt`;

        // Create test file
        await execAsync(
          `kubectl exec -n ${namespace} ${pod.metadata.name} -- sh -c "echo 'persistence test' > /app/uploads/${testFile}"`
        );

        // Verify file exists
        const { stdout } = await execAsync(
          `kubectl exec -n ${namespace} ${pod.metadata.name} -- cat /app/uploads/${testFile}`
        );
        expect(stdout.trim()).toBe('persistence test');

        // File should be accessible from other backend pods
        if (backendPods.body.items.length > 1) {
          const otherPod = backendPods.body.items[1];
          const { stdout: otherPodContent } = await execAsync(
            `kubectl exec -n ${namespace} ${otherPod.metadata.name} -- cat /app/uploads/${testFile}`
          );
          expect(otherPodContent.trim()).toBe('persistence test');
        }
      }
    });
  });

  describe('Storage Performance', () => {
    test('Storage I/O performance is acceptable', async () => {
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

        // Test write performance
        const startTime = Date.now();
        await execAsync(
          `kubectl exec -n ${namespace} ${pod.metadata.name} -- dd if=/dev/zero of=/app/uploads/test-io bs=1M count=10`
        );
        const writeTime = Date.now() - startTime;

        // Should write 10MB in less than 5 seconds
        expect(writeTime).toBeLessThan(5000);

        // Cleanup
        await execAsync(
          `kubectl exec -n ${namespace} ${pod.metadata.name} -- rm -f /app/uploads/test-io`
        );
      }
    });
  });

  describe('EmptyDir Volumes', () => {
    test('Temp directories use emptyDir volumes', async () => {
      const deployment = await k8sAppsApi.readNamespacedDeployment('ytempire-backend', namespace);
      const volumes = deployment.body.spec.template.spec.volumes;

      const tempVolume = volumes.find((v) => v.name === 'temp');
      expect(tempVolume).toBeDefined();
      expect(tempVolume.emptyDir).toBeDefined();
    });

    test('Frontend cache uses emptyDir volume', async () => {
      const deployment = await k8sAppsApi.readNamespacedDeployment('ytempire-frontend', namespace);
      const volumes = deployment.body.spec.template.spec.volumes;

      const cacheVolume = volumes.find((v) => v.name === 'nextjs-cache');
      expect(cacheVolume).toBeDefined();
      expect(cacheVolume.emptyDir).toBeDefined();
    });
  });
});
