/**
 * Database Integration Tests
 * YTEmpire Project
 */

const { Client } = require('pg');
const redis = require('redis');

describe('Database Integration', () => {
  let pgClient;
  let redisClient;

  beforeAll(async () => {
    // PostgreSQL connection
    pgClient = new Client({
      host: 'localhost',
      port: 5432,
      user: 'ytempire_user',
      password: 'ytempire_pass',
      database: 'ytempire_dev',
    });
    await pgClient.connect();

    // Redis connection
    redisClient = redis.createClient({
      url: 'redis://localhost:6379',
    });
    await redisClient.connect();
  });

  afterAll(async () => {
    if (pgClient) await pgClient.end();
    if (redisClient) await redisClient.disconnect();
  });

  test('PostgreSQL connection and CRUD operations', async () => {
    // CREATE
    const createResult = await pgClient.query(
      `INSERT INTO channels (user_id, youtube_channel_id, name, description) 
       VALUES ((SELECT id FROM users LIMIT 1), $1, $2, $3) 
       RETURNING *`,
      ['UC' + Date.now(), 'Test Channel', 'Test Description']
    );
    expect(createResult.rows[0].id).toBeTruthy();

    const channelId = createResult.rows[0].id;

    // READ
    const readResult = await pgClient.query('SELECT * FROM channels WHERE id = $1', [channelId]);
    expect(readResult.rows[0].name).toBe('Test Channel');

    // UPDATE
    const updateResult = await pgClient.query(
      'UPDATE channels SET name = $1 WHERE id = $2 RETURNING *',
      ['Updated Channel', channelId]
    );
    expect(updateResult.rows[0].name).toBe('Updated Channel');

    // DELETE
    const deleteResult = await pgClient.query('DELETE FROM channels WHERE id = $1', [channelId]);
    expect(deleteResult.rowCount).toBe(1);
  });

  test('Database schema validation and migrations', async () => {
    // Check table columns
    const columnsQuery = `
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'videos'
      ORDER BY ordinal_position;
    `;

    const result = await pgClient.query(columnsQuery);
    const columns = result.rows.map((row) => row.column_name);

    expect(columns).toContain('id');
    expect(columns).toContain('channel_id');
    expect(columns).toContain('title');
    expect(columns).toContain('description');
    expect(columns).toContain('status');
    expect(columns).toContain('created_at');
    expect(columns).toContain('updated_at');
  });

  test('Redis cache functionality', async () => {
    // SET operation
    await redisClient.set('test:key', 'test value');

    // GET operation
    const value = await redisClient.get('test:key');
    expect(value).toBe('test value');

    // SET with expiration
    await redisClient.setEx('test:expiring', 2, 'expires soon');
    const expiringValue = await redisClient.get('test:expiring');
    expect(expiringValue).toBe('expires soon');

    // Wait for expiration
    await new Promise((resolve) => setTimeout(resolve, 3000));
    const expiredValue = await redisClient.get('test:expiring');
    expect(expiredValue).toBeNull();

    // Hash operations
    await redisClient.hSet('test:hash', 'field1', 'value1');
    await redisClient.hSet('test:hash', 'field2', 'value2');

    const hashValue = await redisClient.hGet('test:hash', 'field1');
    expect(hashValue).toBe('value1');

    const allHashValues = await redisClient.hGetAll('test:hash');
    expect(allHashValues).toEqual({
      field1: 'value1',
      field2: 'value2',
    });

    // Cleanup
    await redisClient.del('test:key');
    await redisClient.del('test:hash');
  });

  test('PostgreSQL transactions work correctly', async () => {
    const testEmail = `transaction-test-${Date.now()}@example.com`;

    try {
      await pgClient.query('BEGIN');

      // Insert user
      const userResult = await pgClient.query(
        'INSERT INTO users (email, username, password_hash) VALUES ($1, $2, $3) RETURNING id',
        [testEmail, 'transactiontest', 'hash']
      );
      const userId = userResult.rows[0].id;

      // Insert channel
      await pgClient.query(
        'INSERT INTO channels (user_id, youtube_channel_id, name) VALUES ($1, $2, $3)',
        [userId, 'UC' + Date.now(), 'Transaction Test Channel']
      );

      // Verify both exist within transaction
      const checkResult = await pgClient.query(
        'SELECT COUNT(*) as count FROM users WHERE id = $1',
        [userId]
      );
      expect(parseInt(checkResult.rows[0].count)).toBe(1);

      // Rollback transaction
      await pgClient.query('ROLLBACK');

      // Verify rollback worked
      const afterRollback = await pgClient.query(
        'SELECT COUNT(*) as count FROM users WHERE email = $1',
        [testEmail]
      );
      expect(parseInt(afterRollback.rows[0].count)).toBe(0);
    } catch (error) {
      await pgClient.query('ROLLBACK');
      throw error;
    }
  });

  test('Connection pooling works correctly', async () => {
    const promises = [];

    // Create multiple concurrent queries
    for (let i = 0; i < 10; i++) {
      promises.push(pgClient.query('SELECT pg_sleep(0.1), $1::int as num', [i]));
    }

    const results = await Promise.all(promises);

    results.forEach((result, index) => {
      expect(result.rows[0].num).toBe(index);
    });
  });

  test('Redis pub/sub functionality', async () => {
    const subscriber = redis.createClient({ url: 'redis://localhost:6379' });
    const publisher = redis.createClient({ url: 'redis://localhost:6379' });

    await subscriber.connect();
    await publisher.connect();

    const messages = [];

    await subscriber.subscribe('test-channel', (message) => {
      messages.push(message);
    });

    await publisher.publish('test-channel', 'test message 1');
    await publisher.publish('test-channel', 'test message 2');

    await new Promise((resolve) => setTimeout(resolve, 100));

    expect(messages).toEqual(['test message 1', 'test message 2']);

    await subscriber.unsubscribe('test-channel');
    await subscriber.disconnect();
    await publisher.disconnect();
  });

  test('Database backup and restore simulation', async () => {
    // Create test data
    const testData = {
      email: `backup-test-${Date.now()}@example.com`,
      username: `backuptest${Date.now()}`,
      password_hash: 'hash',
    };

    const insertResult = await pgClient.query(
      'INSERT INTO users (email, username, password_hash) VALUES ($1, $2, $3) RETURNING *',
      [testData.email, testData.username, testData.password_hash]
    );

    const userData = insertResult.rows[0];
    expect(userData.id).toBeTruthy();

    // Simulate backup by reading data
    const backupResult = await pgClient.query('SELECT * FROM users WHERE id = $1', [userData.id]);
    const backupData = backupResult.rows[0];

    // Delete original
    await pgClient.query('DELETE FROM users WHERE id = $1', [userData.id]);

    // Simulate restore
    const restoreResult = await pgClient.query(
      'INSERT INTO users (email, username, password_hash, first_name, last_name) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [
        backupData.email + '-restored',
        backupData.username + '-restored',
        backupData.password_hash,
        backupData.first_name,
        backupData.last_name,
      ]
    );

    expect(restoreResult.rows[0].email).toBe(backupData.email + '-restored');

    // Cleanup
    await pgClient.query('DELETE FROM users WHERE id = $1', [restoreResult.rows[0].id]);
  });
});
