module.exports = {
  testEnvironment: 'node',
  coverageDirectory: '../coverage',
  collectCoverageFrom: ['src/**/*.js', '!src/**/*.test.js', '!src/**/*.spec.js'],
  testMatch: ['**/tests/**/*.test.js', '**/tests/**/*.spec.js'],
  testPathIgnorePatterns: ['/node_modules/', '/dist/', '/build/'],
  // Don't run src/routes/test.js as a test
  modulePathIgnorePatterns: ['<rootDir>/src/routes/test.js'],
  verbose: true,
  testTimeout: 30000,
};
