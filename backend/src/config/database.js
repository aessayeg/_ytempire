/**
 * Database Configuration - PostgreSQL configuration with Sequelize
 * YTEmpire Project
 */

const { Sequelize } = require('sequelize');
require('dotenv').config();

// Database connection configuration
const config = {
  development: {
    username: process.env.POSTGRES_USER || 'ytempire_user',
    password: process.env.POSTGRES_PASSWORD || 'ytempire_pass',
    database: process.env.POSTGRES_DB || 'ytempire_dev',
    host: process.env.POSTGRES_HOST || 'postgresql',
    port: process.env.POSTGRES_PORT || 5432,
    dialect: 'postgres',
    logging: console.log,
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    define: {
      timestamps: true,
      underscored: true,
      createdAt: 'created_at',
      updatedAt: 'updated_at'
    }
  },
  test: {
    username: process.env.POSTGRES_USER || 'ytempire_user',
    password: process.env.POSTGRES_PASSWORD || 'ytempire_pass',
    database: 'ytempire_test',
    host: process.env.POSTGRES_HOST || 'postgresql',
    port: process.env.POSTGRES_PORT || 5432,
    dialect: 'postgres',
    logging: false
  },
  production: {
    username: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
    database: process.env.POSTGRES_DB,
    host: process.env.POSTGRES_HOST,
    port: process.env.POSTGRES_PORT,
    dialect: 'postgres',
    logging: false,
    pool: {
      max: 20,
      min: 5,
      acquire: 30000,
      idle: 10000
    }
  }
};

const env = process.env.NODE_ENV || 'development';
const dbConfig = config[env];

// Create Sequelize instance
const sequelize = new Sequelize(
  dbConfig.database,
  dbConfig.username,
  dbConfig.password,
  {
    host: dbConfig.host,
    port: dbConfig.port,
    dialect: dbConfig.dialect,
    logging: dbConfig.logging,
    pool: dbConfig.pool,
    define: dbConfig.define
  }
);

module.exports = {
  sequelize,
  Sequelize,
  config: dbConfig
};