/**
 * Docker Services Tests
 * YTEmpire Project
 */

const axios = require('axios');
const { Client } = require('pg');
const redis = require('redis');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

// Test configuration
const SERVICES = {
  frontend: { url: 'http://localhost:3000', healthEndpoint: '/' },
  backend: { url: 'http://localhost:5000', healthEndpoint: '/health' },
  nginx: { url: 'http://localhost', healthEndpoint: '/health' },
  pgadmin: { url: 'http://localhost:8080', healthEndpoint: '/' },
  mailhog: { url: 'http://localhost:8025', healthEndpoint: '/' },
};

const RETRY_OPTIONS = {
  retries: 10,
  delay: 3000,
  timeout: 60000,
};

// Helper function to wait for service
async function waitForService(serviceName, url, retries = RETRY_OPTIONS.retries) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await axios.get(url, { timeout: 5000 });
      if (response.status === 200 || response.status === 302) {
        return true;
      }
    } catch (error) {
      if (i === retries - 1) {
        throw new Error(`Service ${serviceName} failed to start after ${retries} attempts`);
      }
      await new Promise((resolve) => setTimeout(resolve, RETRY_OPTIONS.delay));
    }
  }
  return false;
}

describe('Docker Compose Services', () => {
  beforeAll(async () => {
    // Start all services
    console.log('Starting Docker Compose services...');
    await execAsync('docker-compose down -v');
    await execAsync('docker-compose up -d --build');

    // Wait for services to be ready
    console.log('Waiting for services to be ready...');
    await new Promise((resolve) => setTimeout(resolve, 10000));
  }, RETRY_OPTIONS.timeout);

  afterAll(async () => {
    // Optional: Keep services running for development
    // await execAsync('docker-compose down');
  });

  test(
    'Frontend service is accessible on port 3000',
    async () => {
      const isReady = await waitForService('frontend', SERVICES.frontend.url);
      expect(isReady).toBe(true);

      const response = await axios.get(SERVICES.frontend.url);
      expect(response.status).toBe(200);
    },
    RETRY_OPTIONS.timeout
  );

  test(
    'Backend service is accessible on port 5000',
    async () => {
      const isReady = await waitForService(
        'backend',
        `${SERVICES.backend.url}${SERVICES.backend.healthEndpoint}`
      );
      expect(isReady).toBe(true);

      const response = await axios.get(`${SERVICES.backend.url}${SERVICES.backend.healthEndpoint}`);
      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('status', 'OK');
    },
    RETRY_OPTIONS.timeout
  );

  test(
    'PostgreSQL is accessible on port 5432',
    async () => {
      const client = new Client({
        host: 'localhost',
        port: 5432,
        user: 'ytempire_user',
        password: 'ytempire_pass',
        database: 'ytempire_dev',
      });

      let connected = false;
      for (let i = 0; i < RETRY_OPTIONS.retries; i++) {
        try {
          await client.connect();
          connected = true;
          break;
        } catch (error) {
          if (i === RETRY_OPTIONS.retries - 1) {
            throw error;
          }
          await new Promise((resolve) => setTimeout(resolve, RETRY_OPTIONS.delay));
        }
      }

      expect(connected).toBe(true);

      // Test database query
      const result = await client.query('SELECT NOW()');
      expect(result.rows).toHaveLength(1);

      await client.end();
    },
    RETRY_OPTIONS.timeout
  );

  test(
    'Redis is accessible on port 6379',
    async () => {
      const client = redis.createClient({
        url: 'redis://localhost:6379',
      });

      let connected = false;
      for (let i = 0; i < RETRY_OPTIONS.retries; i++) {
        try {
          await client.connect();
          connected = true;
          break;
        } catch (error) {
          if (i === RETRY_OPTIONS.retries - 1) {
            throw error;
          }
          await new Promise((resolve) => setTimeout(resolve, RETRY_OPTIONS.delay));
        }
      }

      expect(connected).toBe(true);

      // Test Redis operations
      await client.set('test_key', 'test_value');
      const value = await client.get('test_key');
      expect(value).toBe('test_value');

      await client.disconnect();
    },
    RETRY_OPTIONS.timeout
  );

  test(
    'Nginx proxy routes correctly',
    async () => {
      const isReady = await waitForService('nginx', SERVICES.nginx.url);
      expect(isReady).toBe(true);

      // Test health endpoint
      const healthResponse = await axios.get(
        `${SERVICES.nginx.url}${SERVICES.nginx.healthEndpoint}`
      );
      expect(healthResponse.status).toBe(200);
      expect(healthResponse.data).toContain('healthy');

      // Test API proxy
      const apiResponse = await axios.get(`${SERVICES.nginx.url}/api/health`);
      expect(apiResponse.status).toBe(200);
    },
    RETRY_OPTIONS.timeout
  );

  test(
    'pgAdmin is accessible on port 8080',
    async () => {
      const isReady = await waitForService('pgadmin', SERVICES.pgadmin.url);
      expect(isReady).toBe(true);
    },
    RETRY_OPTIONS.timeout
  );

  test(
    'MailHog UI is accessible on port 8025',
    async () => {
      const isReady = await waitForService('mailhog', SERVICES.mailhog.url);
      expect(isReady).toBe(true);

      const response = await axios.get(`${SERVICES.mailhog.url}/api/v2/messages`);
      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('items');
    },
    RETRY_OPTIONS.timeout
  );

  test('MailHog SMTP is accessible on port 1025', async () => {
    const net = require('net');

    const isPortOpen = await new Promise((resolve) => {
      const socket = new net.Socket();
      socket.setTimeout(5000);

      socket.on('connect', () => {
        socket.destroy();
        resolve(true);
      });

      socket.on('timeout', () => {
        socket.destroy();
        resolve(false);
      });

      socket.on('error', () => {
        resolve(false);
      });

      socket.connect(1025, 'localhost');
    });

    expect(isPortOpen).toBe(true);
  });

  test('All containers are running', async () => {
    const { stdout } = await execAsync('docker-compose ps --format json');
    const containers = stdout
      .trim()
      .split('\n')
      .map((line) => JSON.parse(line));

    const expectedContainers = [
      'ytempire-frontend',
      'ytempire-backend',
      'ytempire-postgresql',
      'ytempire-redis',
      'ytempire-nginx',
      'ytempire-pgadmin',
      'ytempire-mailhog',
    ];

    expectedContainers.forEach((containerName) => {
      const container = containers.find((c) => c.Name === containerName);
      expect(container).toBeDefined();
      expect(container.State).toBe('running');
    });
  });
});
