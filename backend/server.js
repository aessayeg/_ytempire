/**
 * server.js - Main server entry point
 * YTEmpire Project
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { createServer } = require('http');
const { Server } = require('socket.io');

// Import database connection
const { sequelize } = require('./src/models');
const { testConnection } = require('./src/utils/database');

// Import routes (some temporarily disabled for initial setup)
const authRoutes = require('./src/routes/auth');
const userRoutes = require('./src/routes/users');
const testRoutes = require('./src/routes/test');
// const channelRoutes = require('./src/routes/channels');
// const videoRoutes = require('./src/routes/videos');
// const contentRoutes = require('./src/routes/content');
// const analyticsRoutes = require('./src/routes/analytics');
// const automationRoutes = require('./src/routes/automation');

// Import middleware
const errorHandler = require('./src/middleware/errorHandling');
const { authenticateToken } = require('./src/middleware/auth');

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.CLIENT_URL || 'http://localhost:3000',
    credentials: true,
  },
});

// Middleware
app.use(helmet());

// Trust proxy - specifically trust our nginx container
app.set('trust proxy', ['172.20.0.0/16', 'loopback']);

app.use(
  cors({
    origin: process.env.CLIENT_URL,
    credentials: true,
  })
);
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Routes (some temporarily disabled for initial setup)
app.use('/api/auth', authRoutes);
app.use('/api/users', authenticateToken, userRoutes);
app.use('/api/test', testRoutes);
// app.use('/api/channels', authenticateToken, channelRoutes);
// app.use('/api/videos', authenticateToken, videoRoutes);
// app.use('/api/content', authenticateToken, contentRoutes);
// app.use('/api/analytics', authenticateToken, analyticsRoutes);
// app.use('/api/automation', authenticateToken, automationRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Error handling middleware
app.use(errorHandler);

// WebSocket handling
io.on('connection', (socket) => {
  console.log('New client connected:', socket.id);

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });

  // TODO: Implement WebSocket events
});

// Initialize database connection
const initializeDatabase = async () => {
  try {
    // Test database connection
    await testConnection();

    // Don't sync models - tables are already created in PostgreSQL
    // In production, use migrations for schema changes
    console.log('✓ Database models loaded (sync disabled - using existing schema)');
  } catch (error) {
    console.error('✗ Database initialization failed:', error);
    process.exit(1);
  }
};

// Start server
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    // Initialize database first
    await initializeDatabase();

    // Then start the HTTP server
    httpServer.listen(PORT, () => {
      console.log(`✓ Server running on port ${PORT}`);
      console.log(`✓ Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  } catch (error) {
    console.error('✗ Server startup failed:', error);
    process.exit(1);
  }
};

// Handle graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully...');
  httpServer.close(() => {
    console.log('HTTP server closed');
  });
  await sequelize.close();
  process.exit(0);
});

// Start the server
startServer();
