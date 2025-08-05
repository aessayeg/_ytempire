/**
 * Test Routes - Database connectivity testing
 * YTEmpire Project
 */

const express = require('express');
const router = express.Router();
const { sequelize, User } = require('../models');

/**
 * @route   GET /api/test/db
 * @desc    Test database connection
 * @access  Public
 */
router.get('/db', async (req, res) => {
  try {
    await sequelize.authenticate();
    res.json({
      success: true,
      message: 'Database connection successful',
      database: sequelize.config.database,
      host: sequelize.config.host,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Database connection failed',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/test/users
 * @desc    Test user table query
 * @access  Public
 */
router.get('/users', async (req, res) => {
  try {
    const count = await User.count();
    const users = await User.findAll({
      limit: 5,
      attributes: ['account_id', 'email', 'username', 'created_at'],
    });

    res.json({
      success: true,
      count,
      users,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'User query failed',
      error: error.message,
      stack: error.stack,
    });
  }
});

/**
 * @route   GET /api/test/raw
 * @desc    Test raw SQL query
 * @access  Public
 */
router.get('/raw', async (req, res) => {
  try {
    const [results] = await sequelize.query('SELECT * FROM users.accounts LIMIT 5');

    res.json({
      success: true,
      results,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Raw query failed',
      error: error.message,
    });
  }
});

module.exports = router;
