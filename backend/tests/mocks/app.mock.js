/**
 * Mock App for Testing
 * YTEmpire Project
 */

const express = require('express');
const app = express();

// Basic middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Mock routes
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.post('/api/auth/login', (req, res) => {
  res.json({ token: 'mock-token', user: { id: 1, email: 'test@example.com' } });
});

app.post('/api/auth/register', (req, res) => {
  res.status(201).json({ message: 'User created', userId: 1 });
});

// Error handling
app.use((err, req, res, _next) => {
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
  });
});

module.exports = app;
