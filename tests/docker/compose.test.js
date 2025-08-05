/**
 * Docker Compose Tests
 * YTEmpire Project
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

describe('Docker Compose Configuration', () => {
  beforeAll(async () => {
    // Ensure Docker is running
    try {
      await execAsync('docker info');
    } catch (error) {
      throw new Error('Docker is not running. Please start Docker first.');
    }
  }, 30000);

  test('docker-compose.yml file exists', async () => {
    const fs = require('fs').promises;
    const path = require('path');
    const composePath = path.join(process.cwd(), 'docker-compose.yml');
    
    await expect(fs.access(composePath)).resolves.not.toThrow();
  });

  test('docker-compose config is valid', async () => {
    const { stdout, stderr } = await execAsync('docker-compose config');
    expect(stderr).toBe('');
    expect(stdout).toContain('services:');
    expect(stdout).toContain('frontend:');
    expect(stdout).toContain('backend:');
    expect(stdout).toContain('postgresql:');
    expect(stdout).toContain('redis:');
    expect(stdout).toContain('nginx:');
    expect(stdout).toContain('pgadmin:');
    expect(stdout).toContain('mailhog:');
  }, 30000);

  test('all required services are defined', async () => {
    const { stdout } = await execAsync('docker-compose config --services');
    const services = stdout.trim().split('\n');
    
    expect(services).toContain('frontend');
    expect(services).toContain('backend');
    expect(services).toContain('postgresql');
    expect(services).toContain('redis');
    expect(services).toContain('nginx');
    expect(services).toContain('pgadmin');
    expect(services).toContain('mailhog');
  });

  test('volumes are properly configured', async () => {
    const { stdout } = await execAsync('docker-compose config --volumes');
    const volumes = stdout.trim().split('\n');
    
    expect(volumes).toContain('postgres_data');
    expect(volumes).toContain('redis_data');
    expect(volumes).toContain('pgadmin_data');
  });

  test('networks are properly configured', async () => {
    const { stdout } = await execAsync('docker-compose config');
    expect(stdout).toContain('ytempire-network');
    expect(stdout).toContain('172.20.0.0/16');
  });

  test('environment variables are loaded', async () => {
    const { stdout } = await execAsync('docker-compose config');
    
    // Check backend environment
    expect(stdout).toContain('DATABASE_URL');
    expect(stdout).toContain('REDIS_URL');
    expect(stdout).toContain('JWT_SECRET');
    
    // Check frontend environment
    expect(stdout).toContain('NEXT_PUBLIC_API_URL');
    expect(stdout).toContain('NODE_ENV=development');
  });

  test('port mappings are correct', async () => {
    const { stdout } = await execAsync('docker-compose config');
    
    // Frontend port
    expect(stdout).toMatch(/3000:3000/);
    
    // Backend port
    expect(stdout).toMatch(/5000:5000/);
    
    // PostgreSQL port
    expect(stdout).toMatch(/5432:5432/);
    
    // Redis port
    expect(stdout).toMatch(/6379:6379/);
    
    // Nginx ports
    expect(stdout).toMatch(/80:80/);
    expect(stdout).toMatch(/443:443/);
    
    // pgAdmin port
    expect(stdout).toMatch(/8080:80/);
    
    // MailHog ports
    expect(stdout).toMatch(/1025:1025/);
    expect(stdout).toMatch(/8025:8025/);
  });

  test('health checks are configured', async () => {
    const { stdout } = await execAsync('docker-compose config');
    
    expect(stdout).toContain('healthcheck');
    expect(stdout).toContain('pg_isready');
    expect(stdout).toContain('redis-cli');
  });

  test('container dependencies are set', async () => {
    const { stdout } = await execAsync('docker-compose config');
    
    // Frontend depends on backend
    const frontendConfig = stdout.match(/frontend:[\s\S]*?(?=\w+:)/);
    expect(frontendConfig[0]).toContain('depends_on');
    expect(frontendConfig[0]).toContain('backend');
    
    // Backend depends on postgresql, redis, mailhog
    const backendConfig = stdout.match(/backend:[\s\S]*?(?=\w+:)/);
    expect(backendConfig[0]).toContain('depends_on');
    expect(backendConfig[0]).toContain('postgresql');
    expect(backendConfig[0]).toContain('redis');
    expect(backendConfig[0]).toContain('mailhog');
  });
});