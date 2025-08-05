/**
 * Database - Database connection utilities
 * YTEmpire Project
 */

const { sequelize } = require('../config/database');

/**
 * Test database connection
 */
const testConnection = async () => {
  try {
    await sequelize.authenticate();
    console.log('✓ Database connection has been established successfully.');
    return true;
  } catch (error) {
    console.error('✗ Unable to connect to the database:', error);
    return false;
  }
};

/**
 * Sync database models (use with caution in production)
 */
const syncDatabase = async (options = {}) => {
  try {
    await sequelize.sync(options);
    console.log('✓ Database synchronized successfully.');
    return true;
  } catch (error) {
    console.error('✗ Database synchronization failed:', error);
    return false;
  }
};

/**
 * Close database connection
 */
const closeConnection = async () => {
  try {
    await sequelize.close();
    console.log('✓ Database connection closed.');
    return true;
  } catch (error) {
    console.error('✗ Error closing database connection:', error);
    return false;
  }
};

/**
 * Execute raw query
 */
const executeRawQuery = async (query, options = {}) => {
  try {
    const results = await sequelize.query(query, options);
    return results;
  } catch (error) {
    console.error('✗ Raw query execution failed:', error);
    throw error;
  }
};

/**
 * Get database statistics
 */
const getDatabaseStats = async () => {
  try {
    const [results] = await sequelize.query(`
      SELECT 
        schemaname,
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
        n_live_tup AS row_count
      FROM pg_stat_user_tables
      ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
    `);
    return results;
  } catch (error) {
    console.error('✗ Failed to get database stats:', error);
    throw error;
  }
};

module.exports = {
  testConnection,
  syncDatabase,
  closeConnection,
  executeRawQuery,
  getDatabaseStats,
  sequelize
};