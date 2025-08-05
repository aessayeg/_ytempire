/**
 * Service Connectivity Tests
 * YTEmpire Project
 */

const axios = require('axios');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

describe('Service Connectivity', () => {
  test('Frontend can connect to Backend via Nginx', async () => {
    // Test from inside frontend container
    const { stdout } = await execAsync(
      'docker-compose exec -T frontend wget -qO- http://nginx/api/health'
    );
    const response = JSON.parse(stdout);
    expect(response).toHaveProperty('status', 'OK');
  });

  test('Backend can connect to PostgreSQL', async () => {
    const { stdout } = await execAsync(
      'docker-compose exec -T backend node -e "' +
      'const { Client } = require(\'pg\');' +
      'const client = new Client({' +
      '  host: \'postgresql\',' +
      '  port: 5432,' +
      '  user: \'ytempire_user\',' +
      '  password: \'ytempire_pass\',' +
      '  database: \'ytempire_dev\'' +
      '});' +
      'client.connect()' +
      '.then(() => client.query(\'SELECT 1 as connected\'))' +
      '.then(result => {' +
      '  console.log(JSON.stringify(result.rows[0]));' +
      '  client.end();' +
      '})' +
      '.catch(err => {' +
      '  console.error(err);' +
      '  process.exit(1);' +
      '});"'
    );
    
    const result = JSON.parse(stdout);
    expect(result).toHaveProperty('connected', 1);
  });

  test('Backend can connect to Redis', async () => {
    const { stdout } = await execAsync(
      'docker-compose exec -T backend node -e "' +
      'const redis = require(\'redis\');' +
      'const client = redis.createClient({ url: \'redis://redis:6379\' });' +
      'client.connect()' +
      '.then(() => client.ping())' +
      '.then(result => {' +
      '  console.log(JSON.stringify({ ping: result }));' +
      '  client.disconnect();' +
      '})' +
      '.catch(err => {' +
      '  console.error(err);' +
      '  process.exit(1);' +
      '});"'
    );
    
    const result = JSON.parse(stdout);
    expect(result).toHaveProperty('ping', 'PONG');
  });

  test('Backend can connect to MailHog SMTP', async () => {
    const { stdout, stderr } = await execAsync(
      'docker-compose exec -T backend nc -zv mailhog 1025'
    );
    
    // nc outputs to stderr on success
    expect(stderr).toContain('succeeded');
  });

  test('Service discovery works between containers', async () => {
    // Test DNS resolution from backend container
    const services = ['postgresql', 'redis', 'mailhog', 'nginx', 'frontend'];
    
    for (const service of services) {
      const { stdout } = await execAsync(
        `docker-compose exec -T backend nslookup ${service}`
      );
      expect(stdout).toContain(`Name:\t${service}`);
      expect(stdout).toContain('172.20.'); // Our custom network subnet
    }
  });

  test('Nginx can proxy WebSocket connections', async () => {
    // Test Socket.io endpoint through Nginx
    try {
      const response = await axios.get('http://localhost/socket.io/', {
        headers: {
          'Upgrade': 'websocket',
          'Connection': 'Upgrade'
        },
        validateStatus: (status) => status < 500
      });
      
      // Socket.io returns 400 when accessed via regular HTTP (expected)
      expect(response.status).toBe(400);
      expect(response.data).toContain('Transport unknown');
    } catch (error) {
      // This is expected behavior for WebSocket endpoint
      expect(error.response.status).toBe(400);
    }
  });

  test('Frontend build artifacts are accessible', async () => {
    // Check if frontend static files are served correctly
    const { stdout } = await execAsync(
      'docker-compose exec -T nginx ls -la /usr/share/nginx/html/static'
    );
    
    expect(stdout).toContain('favicon.ico');
    expect(stdout).toContain('robots.txt');
  });

  test('Upload directory is mounted and writable', async () => {
    // Test upload directory in backend container
    const testFile = `test-${Date.now()}.txt`;
    
    await execAsync(
      `docker-compose exec -T backend sh -c "echo 'test' > /app/uploads/${testFile}"`
    );
    
    // Verify file exists in mounted volume
    const { stdout } = await execAsync(`ls -la ./uploads/${testFile}`);
    expect(stdout).toContain(testFile);
    
    // Cleanup
    await execAsync(`rm -f ./uploads/${testFile}`);
  });

  test('Inter-service API calls work correctly', async () => {
    // Make an API call from frontend to backend through nginx
    const { stdout } = await execAsync(
      'docker-compose exec -T frontend node -e "' +
      'const http = require(\'http\');' +
      'http.get(\'http://nginx/api/health\', (res) => {' +
      '  let data = \'\';' +
      '  res.on(\'data\', (chunk) => data += chunk);' +
      '  res.on(\'end\', () => {' +
      '    console.log(data);' +
      '  });' +
      '}).on(\'error\', (err) => {' +
      '  console.error(err);' +
      '  process.exit(1);' +
      '});"'
    );
    
    const response = JSON.parse(stdout);
    expect(response).toHaveProperty('status', 'OK');
  });

  test('Database migrations can run', async () => {
    // Test if migrations directory is accessible
    const { stdout } = await execAsync(
      'docker-compose exec -T postgresql ls -la /docker-entrypoint-initdb.d/'
    );
    
    expect(stdout).toContain('01-init.sql');
  });
});