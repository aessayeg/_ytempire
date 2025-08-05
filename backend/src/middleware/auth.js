/**
 * Authentication Middleware - JWT authentication and role authorization
 * YTEmpire Project
 */

const jwt = require('jsonwebtoken');
const { User, Session } = require('../models');

/**
 * Authenticate JWT token
 */
exports.authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({ error: 'Access token required' });
    }

    // Verify JWT token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Check if session exists and is active
    const session = await Session.findOne({
      where: {
        session_token: token,
        account_id: decoded.userId,
        is_active: true
      }
    });

    if (!session) {
      return res.status(401).json({ error: 'Invalid or expired session' });
    }

    // Check if session has expired
    if (new Date() > new Date(session.expires_at)) {
      session.is_active = false;
      await session.save();
      return res.status(401).json({ error: 'Session expired' });
    }

    // Get user details
    const user = await User.findByPk(decoded.userId, {
      attributes: { exclude: ['password_hash'] },
      include: [{
        model: require('../models').Profile,
        as: 'profile'
      }]
    });

    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }

    if (user.account_status !== 'active') {
      return res.status(403).json({ error: 'Account is not active' });
    }

    // Session is valid

    // Attach user to request
    req.user = user;
    req.session = session;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid token' });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    console.error('Authentication error:', error);
    return res.status(500).json({ error: 'Authentication failed' });
  }
};

/**
 * Authorize based on user role/account type
 */
exports.authorizeRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    if (!allowedRoles.includes(req.user.account_type)) {
      return res.status(403).json({ 
        error: 'Insufficient permissions',
        required: allowedRoles,
        current: req.user.account_type
      });
    }

    next();
  };
};

/**
 * Optional authentication - doesn't fail if no token
 */
exports.optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return next();
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    const session = await Session.findOne({
      where: {
        session_token: token,
        account_id: decoded.userId,
        is_active: true
      }
    });

    if (session && new Date() <= new Date(session.expires_at)) {
      const user = await User.findByPk(decoded.userId, {
        attributes: { exclude: ['password_hash'] }
      });
      
      if (user && user.account_status === 'active') {
        req.user = user;
        req.session = session;
      }
    }
  } catch (error) {
    // Ignore errors for optional auth
  }
  
  next();
};