/**
 * PostgreSQL Database Tests
 * YTEmpire Project
 */

const { Client } = require('pg');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

describe('PostgreSQL Database Integration', () => {
  let client;

  beforeAll(async () => {
    // Wait for PostgreSQL to be ready
    await new Promise((resolve) => setTimeout(resolve, 5000));

    client = new Client({
      host: 'localhost',
      port: 5432,
      user: 'ytempire_user',
      password: 'ytempire_pass',
      database: 'ytempire_dev',
    });

    await client.connect();
  });

  afterAll(async () => {
    if (client) {
      await client.end();
    }
  });

  test('PostgreSQL connection establishes successfully', async () => {
    const result = await client.query('SELECT version()');
    expect(result.rows[0].version).toContain('PostgreSQL');
  });

  test('Database migrations run correctly', async () => {
    // Check if all tables exist
    const tablesQuery = `
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    `;

    const result = await client.query(tablesQuery);
    const tables = result.rows.map((row) => row.table_name);

    expect(tables).toContain('users');
    expect(tables).toContain('channels');
    expect(tables).toContain('videos');
    expect(tables).toContain('analytics');
  });

  test('Seed data loads properly', async () => {
    // Check if sample users were created
    const result = await client.query('SELECT * FROM users WHERE email IN ($1, $2)', [
      'admin@ytempire.local',
      'test@ytempire.local',
    ]);

    expect(result.rows).toHaveLength(2);

    const admin = result.rows.find((u) => u.email === 'admin@ytempire.local');
    expect(admin.username).toBe('admin');
    expect(admin.role).toBe('admin');

    const testUser = result.rows.find((u) => u.email === 'test@ytempire.local');
    expect(testUser.username).toBe('testuser');
    expect(testUser.role).toBe('user');
  });

  test('SQL queries execute successfully', async () => {
    // Test INSERT
    const insertResult = await client.query(
      'INSERT INTO users (email, username, password_hash, first_name, last_name) VALUES ($1, $2, $3, $4, $5) RETURNING id',
      ['test-' + Date.now() + '@example.com', 'testuser' + Date.now(), 'hash', 'Test', 'User']
    );
    expect(insertResult.rows[0].id).toBeTruthy();

    const userId = insertResult.rows[0].id;

    // Test SELECT
    const selectResult = await client.query('SELECT * FROM users WHERE id = $1', [userId]);
    expect(selectResult.rows).toHaveLength(1);

    // Test UPDATE
    const updateResult = await client.query(
      'UPDATE users SET first_name = $1 WHERE id = $2 RETURNING first_name',
      ['Updated', userId]
    );
    expect(updateResult.rows[0].first_name).toBe('Updated');

    // Test DELETE
    const deleteResult = await client.query('DELETE FROM users WHERE id = $1', [userId]);
    expect(deleteResult.rowCount).toBe(1);
  });

  test('Database constraints and indexes work', async () => {
    // Test unique constraint on email
    try {
      await client.query('INSERT INTO users (email, username, password_hash) VALUES ($1, $2, $3)', [
        'admin@ytempire.local',
        'duplicate',
        'hash',
      ]);
      fail('Should have thrown unique constraint error');
    } catch (error) {
      expect(error.code).toBe('23505'); // Unique violation
    }

    // Check indexes exist
    const indexQuery = `
      SELECT indexname 
      FROM pg_indexes 
      WHERE schemaname = 'public' 
      AND tablename = 'users';
    `;

    const indexResult = await client.query(indexQuery);
    const indexes = indexResult.rows.map((row) => row.indexname);

    expect(indexes).toContain('idx_users_email');
    expect(indexes).toContain('idx_users_username');
  });

  test('Connection pooling functions correctly', async () => {
    // Create multiple connections
    const connections = [];

    for (let i = 0; i < 5; i++) {
      const newClient = new Client({
        host: 'localhost',
        port: 5432,
        user: 'ytempire_user',
        password: 'ytempire_pass',
        database: 'ytempire_dev',
      });

      await newClient.connect();
      connections.push(newClient);
    }

    // Execute queries on all connections
    const promises = connections.map((conn, index) =>
      conn.query('SELECT $1::int as number', [index])
    );

    const results = await Promise.all(promises);

    results.forEach((result, index) => {
      expect(result.rows[0].number).toBe(index);
    });

    // Close all connections
    await Promise.all(connections.map((conn) => conn.end()));
  });

  test('Triggers and functions work correctly', async () => {
    // Insert a user and check created_at
    const insertResult = await client.query(
      'INSERT INTO users (email, username, password_hash) VALUES ($1, $2, $3) RETURNING id, created_at, updated_at',
      ['trigger-test@example.com', 'triggertest', 'hash']
    );

    const userId = insertResult.rows[0].id;
    const createdAt = insertResult.rows[0].created_at;
    const updatedAt = insertResult.rows[0].updated_at;

    expect(createdAt).toBeTruthy();
    expect(updatedAt).toBeTruthy();
    expect(createdAt).toEqual(updatedAt);

    // Wait a moment and update the user
    await new Promise((resolve) => setTimeout(resolve, 1000));

    const updateResult = await client.query(
      'UPDATE users SET first_name = $1 WHERE id = $2 RETURNING updated_at',
      ['Updated', userId]
    );

    const newUpdatedAt = updateResult.rows[0].updated_at;
    expect(new Date(newUpdatedAt).getTime()).toBeGreaterThan(new Date(updatedAt).getTime());

    // Cleanup
    await client.query('DELETE FROM users WHERE id = $1', [userId]);
  });

  test('Extensions are properly installed', async () => {
    const result = await client.query('SELECT extname FROM pg_extension');
    const extensions = result.rows.map((row) => row.extname);

    expect(extensions).toContain('uuid-ossp');
    expect(extensions).toContain('pgcrypto');
  });

  test('Schema and permissions are correct', async () => {
    // Check user permissions
    const permQuery = `
      SELECT has_table_privilege('ytempire_user', 'users', 'SELECT') as can_select,
             has_table_privilege('ytempire_user', 'users', 'INSERT') as can_insert,
             has_table_privilege('ytempire_user', 'users', 'UPDATE') as can_update,
             has_table_privilege('ytempire_user', 'users', 'DELETE') as can_delete;
    `;

    const result = await client.query(permQuery);
    const perms = result.rows[0];

    expect(perms.can_select).toBe(true);
    expect(perms.can_insert).toBe(true);
    expect(perms.can_update).toBe(true);
    expect(perms.can_delete).toBe(true);
  });
});
