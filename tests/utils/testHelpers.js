/**
 * Test Helper Functions
 * YTEmpire Project
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const axios = require('axios');
const execAsync = promisify(exec);

/**
 * Wait for a service to be ready
 */
async function waitForService(url, maxRetries = 30, delay = 2000) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await axios.get(url, { timeout: 5000 });
      if (response.status === 200 || response.status === 302) {
        return true;
      }
    } catch (error) {
      if (i === maxRetries - 1) {
        throw new Error(`Service at ${url} failed to start after ${maxRetries} attempts`);
      }
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
  return false;
}

/**
 * Check if Docker is running
 */
async function checkDocker() {
  try {
    await execAsync('docker info');
    return true;
  } catch (error) {
    return false;
  }
}

/**
 * Start Docker Compose services
 */
async function startServices() {
  console.log('Starting Docker Compose services...');

  // Stop any existing services
  await execAsync('docker-compose down -v').catch(() => {});

  // Start services
  await execAsync('docker-compose up -d --build');

  // Wait for services to be ready
  console.log('Waiting for services to be ready...');
  await new Promise((resolve) => setTimeout(resolve, 10000));

  // Wait for specific services
  const services = [
    { name: 'Frontend', url: 'http://localhost:3000' },
    { name: 'Backend', url: 'http://localhost:5000/health' },
    { name: 'Nginx', url: 'http://localhost/health' },
    { name: 'pgAdmin', url: 'http://localhost:8080' },
    { name: 'MailHog', url: 'http://localhost:8025' },
  ];

  for (const service of services) {
    console.log(`Waiting for ${service.name}...`);
    await waitForService(service.url);
    console.log(`${service.name} is ready`);
  }
}

/**
 * Stop Docker Compose services
 */
async function stopServices() {
  console.log('Stopping Docker Compose services...');
  await execAsync('docker-compose down');
}

/**
 * Get container logs
 */
async function getContainerLogs(containerName) {
  try {
    const { stdout } = await execAsync(`docker logs ${containerName} --tail 100`);
    return stdout;
  } catch (error) {
    return error.stderr || error.message;
  }
}

/**
 * Execute command in container
 */
async function execInContainer(containerName, command) {
  const { stdout, stderr } = await execAsync(`docker-compose exec -T ${containerName} ${command}`);
  return { stdout, stderr };
}

/**
 * Check if container is running
 */
async function isContainerRunning(containerName) {
  try {
    const { stdout } = await execAsync(
      `docker ps --filter "name=${containerName}" --format "{{.Names}}"`
    );
    return stdout.trim() === containerName;
  } catch (error) {
    return false;
  }
}

/**
 * Wait for PostgreSQL to be ready
 */
async function waitForPostgres(maxRetries = 30) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      await execAsync(
        'docker-compose exec -T postgresql pg_isready -U ytempire_user -d ytempire_dev'
      );
      return true;
    } catch (error) {
      if (i === maxRetries - 1) {
        throw new Error('PostgreSQL failed to become ready');
      }
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  }
}

/**
 * Wait for Redis to be ready
 */
async function waitForRedis(maxRetries = 30) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      await execAsync('docker-compose exec -T redis redis-cli ping');
      return true;
    } catch (error) {
      if (i === maxRetries - 1) {
        throw new Error('Redis failed to become ready');
      }
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  }
}

/**
 * Create test user in database
 */
async function createTestUser(email, password = 'password123') {
  const { Client } = require('pg');
  const bcrypt = require('bcryptjs');

  const client = new Client({
    host: 'localhost',
    port: 5432,
    user: 'ytempire_user',
    password: 'ytempire_pass',
    database: 'ytempire_dev',
  });

  await client.connect();

  const passwordHash = await bcrypt.hash(password, 10);

  const result = await client.query(
    'INSERT INTO users (email, username, password_hash, first_name, last_name) VALUES ($1, $2, $3, $4, $5) RETURNING *',
    [email, email.split('@')[0], passwordHash, 'Test', 'User']
  );

  await client.end();

  return result.rows[0];
}

/**
 * Clean test data from database
 */
async function cleanTestData() {
  const { Client } = require('pg');

  const client = new Client({
    host: 'localhost',
    port: 5432,
    user: 'ytempire_user',
    password: 'ytempire_pass',
    database: 'ytempire_dev',
  });

  await client.connect();

  // Delete test users (except seeded ones)
  await client.query('DELETE FROM users WHERE email LIKE \'test-%\' OR email LIKE \'%-test@%\'');

  await client.end();
}

module.exports = {
  waitForService,
  checkDocker,
  startServices,
  stopServices,
  getContainerLogs,
  execInContainer,
  isContainerRunning,
  waitForPostgres,
  waitForRedis,
  createTestUser,
  cleanTestData,
};
