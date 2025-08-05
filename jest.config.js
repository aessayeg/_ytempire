module.exports = {
  // Test environment
  testEnvironment: 'node',
  
  // Root directories
  roots: ['<rootDir>/tests', '<rootDir>/backend', '<rootDir>/frontend'],
  
  // Test match patterns
  testMatch: [
    '**/__tests__/**/*.js',
    '**/*.test.js',
    '**/*.spec.js'
  ],
  
  // Coverage configuration
  collectCoverage: true,
  collectCoverageFrom: [
    'backend/**/*.js',
    'frontend/**/*.{js,jsx}',
    '!**/node_modules/**',
    '!**/vendor/**',
    '!**/*.config.js',
    '!**/coverage/**',
    '!**/dist/**',
    '!**/build/**'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html', 'json-summary'],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 85,
      statements: 85
    }
  },
  
  // Transform files
  transform: {
    '^.+\\.jsx?$': 'babel-jest'
  },
  
  // Module name mapper for aliases
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
    '^@backend/(.*)$': '<rootDir>/backend/$1',
    '^@frontend/(.*)$': '<rootDir>/frontend/$1',
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy'
  },
  
  // Setup files
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  
  // Ignore patterns
  testPathIgnorePatterns: [
    '/node_modules/',
    '/dist/',
    '/build/',
    '/.next/'
  ],
  
  // Verbose output
  verbose: true,
  
  // Test timeout
  testTimeout: 30000,
  
  // Globals
  globals: {
    'NODE_ENV': 'test'
  }
};