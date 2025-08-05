/**
 * Jest Configuration for Kubernetes Tests
 * YTEmpire Project
 */

module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/kubernetes/**/*.test.js'],
  testTimeout: 120000, // 2 minutes per test
  setupFilesAfterEnv: ['<rootDir>/tests/kubernetes/setup.js'],
  collectCoverage: true,
  coverageDirectory: 'coverage/kubernetes',
  coverageReporters: ['text', 'html', 'json'],
  collectCoverageFrom: [
    'tests/kubernetes/**/*.js',
    '!tests/kubernetes/setup.js',
    '!tests/kubernetes/utils/**',
  ],
  verbose: true,
  forceExit: true,
  detectOpenHandles: true,
  maxWorkers: 1, // Run tests sequentially
  globals: {
    K8S_TEST: true,
  },
};
