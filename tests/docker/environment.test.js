/**
 * Environment Configuration Tests
 * YTEmpire Project
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

describe('Environment Configuration', () => {
  test('All required environment variables are loaded in backend', async () => {
    const { stdout } = await execAsync(
      'docker-compose exec -T backend node -e "console.log(JSON.stringify(process.env))"'
    );
    
    const env = JSON.parse(stdout);
    
    // Core environment variables
    expect(env.NODE_ENV).toBe('development');
    expect(env.PORT).toBe('5000');
    
    // Database configuration
    expect(env.DATABASE_URL).toContain('postgresql://ytempire_user:ytempire_pass@postgresql:5432/ytempire_dev');
    expect(env.DB_HOST).toBe('postgresql');
    expect(env.DB_PORT).toBe('5432');
    expect(env.DB_NAME).toBe('ytempire_dev');
    
    // Redis configuration
    expect(env.REDIS_URL).toBe('redis://redis:6379');
    expect(env.REDIS_HOST).toBe('redis');
    
    // JWT configuration
    expect(env.JWT_SECRET).toBeTruthy();
    expect(env.JWT_SECRET).not.toBe('your-jwt-secret-here');
    
    // File storage configuration
    expect(env.UPLOAD_PATH).toBe('/app/uploads');
    expect(env.TEMP_PATH).toBe('/app/temp');
    
    // Email configuration
    expect(env.SMTP_HOST).toBe('mailhog');
    expect(env.SMTP_PORT).toBe('1025');
    expect(env.EMAIL_FROM).toBe('noreply@ytempire.local');
  });

  test('All required environment variables are loaded in frontend', async () => {
    const { stdout } = await execAsync(
      'docker-compose exec -T frontend node -e "console.log(JSON.stringify(process.env))"'
    );
    
    const env = JSON.parse(stdout);
    
    expect(env.NODE_ENV).toBe('development');
    expect(env.NEXT_PUBLIC_API_URL).toBe('http://localhost/api');
    expect(env.NEXT_PUBLIC_APP_NAME).toBe('YTEmpire');
    expect(env.NEXT_PUBLIC_WEBSOCKET_URL).toBe('ws://localhost:5000');
  });

  test('Service discovery works between containers', async () => {
    // Test if backend can resolve other service hostnames
    const services = ['postgresql', 'redis', 'mailhog', 'frontend', 'nginx'];
    
    for (const service of services) {
      const { exitCode } = await execAsync(
        `docker-compose exec -T backend ping -c 1 ${service}`
      ).catch(err => err);
      
      expect(exitCode).toBe(0);
    }
  });

  test('YouTube API configuration is present', async () => {
    const { stdout } = await execAsync(
      'docker-compose exec -T backend printenv | grep YOUTUBE'
    );
    
    expect(stdout).toContain('YOUTUBE_API_KEY=');
    expect(stdout).toContain('YOUTUBE_CLIENT_ID=');
    expect(stdout).toContain('YOUTUBE_CLIENT_SECRET=');
  });

  test('OpenAI/Claude API keys are configured', async () => {
    const { stdout } = await execAsync(
      'docker-compose exec -T backend printenv | grep -E "(OPENAI|CLAUDE)"'
    );
    
    expect(stdout).toContain('OPENAI_API_KEY=');
    expect(stdout).toContain('CLAUDE_API_KEY=');
  });

  test('Local file storage paths are configured', async () => {
    // Check if directories exist in backend container
    const { stdout: uploadsCheck } = await execAsync(
      'docker-compose exec -T backend ls -la /app/uploads'
    );
    expect(uploadsCheck).toContain('drwxr');
    
    const { stdout: tempCheck } = await execAsync(
      'docker-compose exec -T backend ls -la /app/temp'
    );
    expect(tempCheck).toContain('drwxr');
  });

  test('Email configuration points to MailHog', async () => {
    const { stdout } = await execAsync(
      'docker-compose exec -T backend printenv | grep SMTP'
    );
    
    expect(stdout).toContain('SMTP_HOST=mailhog');
    expect(stdout).toContain('SMTP_PORT=1025');
    expect(stdout).toContain('SMTP_SECURE=false');
  });

  test('No AWS credentials are required for MVP', async () => {
    const { stdout } = await execAsync(
      'docker-compose exec -T backend printenv | grep AWS || echo "No AWS vars"'
    );
    
    // Should not find any AWS environment variables
    expect(stdout.trim()).toBe('No AWS vars');
  });

  test('PostgreSQL is properly initialized', async () => {
    const { stdout } = await execAsync(
      'docker-compose exec -T postgresql psql -U ytempire_user -d ytempire_dev -c "\\dt"'
    );
    
    // Check if tables were created
    expect(stdout).toContain('users');
    expect(stdout).toContain('channels');
    expect(stdout).toContain('videos');
    expect(stdout).toContain('analytics');
  });

  test('Redis is accessible without password', async () => {
    const { stdout } = await execAsync(
      'docker-compose exec -T redis redis-cli ping'
    );
    
    expect(stdout.trim()).toBe('PONG');
  });

  test('Development volumes are mounted correctly', async () => {
    // Check frontend volume
    const { stdout: frontendVol } = await execAsync(
      'docker-compose exec -T frontend ls -la /app/src'
    );
    expect(frontendVol).toContain('components');
    expect(frontendVol).toContain('pages');
    
    // Check backend volume
    const { stdout: backendVol } = await execAsync(
      'docker-compose exec -T backend ls -la /app/src'
    );
    expect(backendVol).toContain('controllers');
    expect(backendVol).toContain('models');
    expect(backendVol).toContain('routes');
  });

  test('Node modules are not synced (for performance)', async () => {
    // Verify node_modules are using anonymous volumes
    const { stdout } = await execAsync('docker volume ls | grep node_modules');
    expect(stdout).toBeTruthy();
  });
});