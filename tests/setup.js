/**
 * Test Setup File
 * YTEmpire Project
 */

const { checkDocker } = require('./utils/testHelpers');

// Increase Jest timeout for Docker tests
jest.setTimeout(120000);

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-ytempire';
process.env.SESSION_SECRET = 'test-session-secret-ytempire';
process.env.DATABASE_URL = 'postgresql://ytempire_user:ytempire_pass@localhost:5432/ytempire_dev';
process.env.REDIS_URL = 'redis://localhost:6379';
process.env.PORT = '5000';

// Global setup
beforeAll(async () => {
  // Check if Docker is running
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    console.warn('Docker is not running. Some integration tests may fail.');
  } else {
    console.log('Docker is running. Starting tests...');
  }
});

// Global teardown
afterAll(async () => {
  // Optional: Add global cleanup here
  console.log('All tests completed.');
});

// Suppress console errors during tests (optional)
const originalError = console.error;
const originalLog = console.log;

beforeEach(() => {
  // Optionally suppress console output during tests
  // console.error = jest.fn();
  // console.log = jest.fn();
});

afterEach(() => {
  console.error = originalError;
  console.log = originalLog;
});

// Add custom Jest matchers
expect.extend({
  toBeWithinRange(received, floor, ceiling) {
    const pass = received >= floor && received <= ceiling;
    if (pass) {
      return {
        message: () => `expected ${received} not to be within range ${floor} - ${ceiling}`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected ${received} to be within range ${floor} - ${ceiling}`,
        pass: false,
      };
    }
  },

  toBeValidUUID(received) {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    const pass = uuidRegex.test(received);
    return {
      message: () =>
        pass
          ? `expected ${received} not to be a valid UUID`
          : `expected ${received} to be a valid UUID`,
      pass,
    };
  },

  toBeValidEmail(received) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const pass = emailRegex.test(received);
    return {
      message: () =>
        pass
          ? `expected ${received} not to be a valid email`
          : `expected ${received} to be a valid email`,
      pass,
    };
  },
});

// Global test utilities
global.testUtils = {
  // Generate test user data
  generateUser: (overrides = {}) => ({
    id: Math.random().toString(36).substr(2, 9),
    email: `test${Date.now()}@example.com`,
    username: `testuser${Date.now()}`,
    password: 'TestPassword123!',
    created_at: new Date().toISOString(),
    ...overrides,
  }),

  // Generate test channel data for YTEmpire
  generateChannel: (overrides = {}) => {
    // Generate exactly 22 characters after UC prefix
    const randomChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
    let channelId = 'UC';
    for (let i = 0; i < 22; i++) {
      channelId += randomChars.charAt(Math.floor(Math.random() * randomChars.length));
    }
    return {
      id: Math.random().toString(36).substr(2, 9),
      name: `Test Channel ${Date.now()}`,
      youtube_id: channelId,
      description: 'Test channel description',
      subscriber_count: Math.floor(Math.random() * 100000),
      video_count: Math.floor(Math.random() * 1000),
      created_at: new Date().toISOString(),
      ...overrides,
    };
  },

  // Generate test video data
  generateVideo: (overrides = {}) => {
    // Generate exactly 11 characters for YouTube video ID
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
    let videoId = '';
    for (let i = 0; i < 11; i++) {
      videoId += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return {
      id: Math.random().toString(36).substr(2, 9),
      channel_id: Math.random().toString(36).substr(2, 9),
      title: `Test Video ${Date.now()}`,
      youtube_id: videoId,
      description: 'Test video description',
      duration: Math.floor(Math.random() * 3600),
      view_count: Math.floor(Math.random() * 1000000),
      like_count: Math.floor(Math.random() * 10000),
      comment_count: Math.floor(Math.random() * 1000),
      published_at: new Date().toISOString(),
      ...overrides,
    };
  },

  // Generate test analytics data
  generateAnalytics: (overrides = {}) => ({
    id: Math.random().toString(36).substr(2, 9),
    video_id: Math.random().toString(36).substr(2, 9),
    date: new Date().toISOString().split('T')[0],
    views: Math.floor(Math.random() * 10000),
    watch_time_minutes: Math.floor(Math.random() * 100000),
    average_view_duration: Math.floor(Math.random() * 600),
    click_through_rate: Math.random() * 10,
    ...overrides,
  }),

  // Generate JWT token for testing
  generateTestToken: (userId = 'test-user-id') => {
    // This is a mock token for testing
    return `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.${Buffer.from(
      JSON.stringify({
        userId,
        email: 'test@example.com',
        iat: Date.now() / 1000,
        exp: Date.now() / 1000 + 3600,
      })
    ).toString('base64')}.test-signature`;
  },

  // Wait for condition
  waitFor: async (condition, timeout = 5000, interval = 100) => {
    const startTime = Date.now();
    while (Date.now() - startTime < timeout) {
      if (await condition()) {
        return true;
      }
      await new Promise((resolve) => setTimeout(resolve, interval));
    }
    throw new Error(`Condition not met within ${timeout}ms`);
  },

  // Database connection mock
  mockDatabaseConnection: () => ({
    query: jest.fn().mockResolvedValue({ rows: [] }),
    connect: jest.fn().mockResolvedValue(undefined),
    end: jest.fn().mockResolvedValue(undefined),
  }),

  // Redis client mock
  mockRedisClient: () => ({
    connect: jest.fn().mockResolvedValue(undefined),
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue('OK'),
    del: jest.fn().mockResolvedValue(1),
    quit: jest.fn().mockResolvedValue(undefined),
  }),
};
