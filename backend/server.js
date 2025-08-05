/**
 * server.js - Main server entry point
 * YTEmpire Project
 */

require('dotenv').config();
const express = require('express');
// const mongoose = require('mongoose'); // TODO: Replace with PostgreSQL connection
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { createServer } = require('http');
const { Server } = require('socket.io');

// Import routes (some temporarily disabled for initial setup)
const authRoutes = require('./src/routes/auth');
const userRoutes = require('./src/routes/users');
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
    origin: process.env.CLIENT_URL,
    credentials: true
  }
});

// Middleware
app.use(helmet());

// Trust proxy - specifically trust our nginx container
app.set('trust proxy', ['172.20.0.0/16', 'loopback']);

app.use(cors({
  origin: process.env.CLIENT_URL,
  credentials: true
}));
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Routes (some temporarily disabled for initial setup)
app.use('/api/auth', authRoutes);
app.use('/api/users', authenticateToken, userRoutes);
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

// Database connection (temporarily disabled for initial setup)
// TODO: Configure PostgreSQL connection instead of MongoDB
// mongoose.connect(process.env.MONGODB_URI, {
//   useNewUrlParser: true,
//   useUnifiedTopology: true
// })
// .then(() => console.log('MongoDB connected'))
// .catch(err => console.error('MongoDB connection error:', err));

// Start server
const PORT = process.env.PORT || 5000;
httpServer.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});