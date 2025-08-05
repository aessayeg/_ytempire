/**
 * Routes Index
 * YTEmpire Project
 */

const express = require('express');
const router = express.Router();

// Import route modules
const authRoutes = require('./auth');
const userRoutes = require('./users');
const channelRoutes = require('./channels');
const videoRoutes = require('./videos');
const analyticsRoutes = require('./analytics');
const automationRoutes = require('./automation');
const contentRoutes = require('./content');

// Mount routes
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/channels', channelRoutes);
router.use('/videos', videoRoutes);
router.use('/analytics', analyticsRoutes);
router.use('/automation', automationRoutes);
router.use('/content', contentRoutes);

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'YTEmpire API',
    version: '1.0.0',
  });
});

module.exports = router;
