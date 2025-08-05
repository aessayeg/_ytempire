/**
 * Test Setup File
 * YTEmpire Project
 */

const { checkDocker } = require('./utils/testHelpers');

// Increase Jest timeout for Docker tests
jest.setTimeout(120000);

// Global setup
beforeAll(async () => {
  // Check if Docker is running
  const dockerRunning = await checkDocker();
  if (!dockerRunning) {
    throw new Error('Docker is not running. Please start Docker Desktop and try again.');
  }
  
  console.log('Docker is running. Starting tests...');
});

// Global teardown
afterAll(async () => {
  // Optional: Add global cleanup here
  console.log('All tests completed.');
});

// Suppress console errors during tests
const originalError = console.error;
beforeEach(() => {
  console.error = jest.fn();
});

afterEach(() => {
  console.error = originalError;
});