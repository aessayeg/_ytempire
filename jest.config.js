module.exports = {
  // Test environment
  testEnvironment: 'node',

  // Root directories
  roots: ['<rootDir>/tests', '<rootDir>/backend', '<rootDir>/frontend'],

  // Test match patterns
  testMatch: ['**/__tests__/**/*.js', '**/*.test.js', '**/*.spec.js'],

  // Coverage configuration
  collectCoverage: true,
  collectCoverageFrom: [
    'backend/**/*.js',
    '!frontend/**', // Exclude frontend files to avoid JSX issues
    '!**/node_modules/**',
    '!**/vendor/**',
    '!**/*.config.js',
    '!**/coverage/**',
    '!**/dist/**',
    '!**/build/**',
    '!**/*.test.js',
    '!**/*.spec.js',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html', 'json-summary'],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 85,
      statements: 85,
    },
  },

  // Transform files
  transform: {
    '^.+\\.(js|jsx)$': 'babel-jest',
  },
  transformIgnorePatterns: ['node_modules/(?!(react|react-dom)/)'],

  // Module name mapper for aliases
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
    '^@backend/(.*)$': '<rootDir>/backend/$1',
    '^@frontend/(.*)$': '<rootDir>/frontend/$1',
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
  },

  // Setup files
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],

  // Ignore patterns
  testPathIgnorePatterns: [
    '/node_modules/',
    '/dist/',
    '/build/',
    '/.next/',
    '/tests/e2e/', // Exclude E2E tests that use Cypress
  ],

  // Verbose output
  verbose: true,

  // Test timeout
  testTimeout: 30000,

  // Globals
  globals: {
    NODE_ENV: 'test',
  },
};
