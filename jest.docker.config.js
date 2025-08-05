/**
 * Jest Configuration for Docker Tests
 * YTEmpire Project
 */

module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/docker/**/*.test.js', '**/tests/integration/**/*.test.js'],
  testTimeout: 120000, // 2 minutes per test
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  collectCoverage: true,
  coverageDirectory: 'coverage/docker',
  coverageReporters: ['text', 'html', 'json'],
  collectCoverageFrom: ['tests/**/*.js', '!tests/setup.js', '!tests/utils/**'],
  verbose: true,
  forceExit: true,
  detectOpenHandles: true,
  maxWorkers: 1, // Run tests sequentially
  globals: {
    DOCKER_TEST: true,
  },
};
