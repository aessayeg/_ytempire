/**
 * AuthController - Authentication controller
 * YTEmpire Project
 */

const jwt = require('jsonwebtoken');
// const crypto = require('crypto'); // TODO: Use for password reset tokens
const { User, Profile, Session } = require('../models');
const { Op } = require('sequelize');

/**
 * Register a new user
 */
exports.register = async (req, res, next) => {
  try {
    const { email, username, password, accountType = 'creator' } = req.body;

    // Validate input
    if (!email || !username || !password) {
      return res.status(400).json({
        error: 'Email, username and password are required',
      });
    }

    // Check if user exists
    console.log('Checking for existing user with email:', email, 'or username:', username);
    const existingUser = await User.findOne({
      where: {
        [Op.or]: [{ email }, { username }],
      },
    });

    if (existingUser) {
      return res.status(409).json({
        error: 'User with this email or username already exists',
      });
    }

    // Create user (password will be hashed by model hook)
    const user = await User.create({
      email,
      username,
      password_hash: password,
      account_type: accountType,
    });

    // Create default profile
    await Profile.create({
      account_id: user.account_id,
      display_name: username,
    });

    // Create session
    const token = jwt.sign({ userId: user.account_id, email: user.email }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRE || '7d',
    });

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    const _session = await Session.create({
      account_id: user.account_id,
      session_token: token,
      ip_address: req.ip,
      user_agent: req.headers['user-agent'],
      expires_at: expiresAt,
    });

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: user.toJSON(),
        token,
        expiresAt,
      },
    });
  } catch (error) {
    console.error('Registration error:', error.message);
    console.error('SQL:', error.sql);
    console.error('Original:', error.original);
    next(error);
  }
};

/**
 * Login user
 */
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        error: 'Email and password are required',
      });
    }

    // Find user by email or username
    const user = await User.findOne({
      where: {
        [Op.or]: [{ email }, { username: email }],
      },
      include: [
        {
          model: Profile,
          as: 'profile',
        },
      ],
    });

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Verify password
    const isValidPassword = await user.validatePassword(password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check account status
    if (user.account_status !== 'active') {
      return res.status(403).json({
        error: `Account is ${user.account_status}`,
      });
    }

    // Create session
    const token = jwt.sign({ userId: user.account_id, email: user.email }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRE || '7d',
    });

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    const _session = await Session.create({
      account_id: user.account_id,
      session_token: token,
      ip_address: req.ip,
      user_agent: req.headers['user-agent'],
      expires_at: expiresAt,
    });

    // Update last login
    user.last_login_at = new Date();
    user.last_login_ip = req.ip;
    await user.save();

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: user.toJSON(),
        token,
        expiresAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Logout user
 */
exports.logout = async (req, res, next) => {
  try {
    if (req.session) {
      req.session.is_active = false;
      await req.session.save();
    }

    res.json({
      success: true,
      message: 'Logout successful',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get current user
 */
exports.me = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.user.account_id, {
      include: [
        {
          model: Profile,
          as: 'profile',
        },
      ],
    });

    res.json({
      success: true,
      data: user.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Refresh token
 */
exports.refresh = async (req, res, next) => {
  try {
    const { token: oldToken } = req.body;

    if (!oldToken) {
      return res.status(400).json({ error: 'Token required for refresh' });
    }

    // Verify old token (even if expired)
    let decoded;
    try {
      decoded = jwt.verify(oldToken, process.env.JWT_SECRET, { ignoreExpiration: true });
    } catch (error) {
      return res.status(401).json({ error: 'Invalid token' });
    }

    // Find session by old token
    const session = await Session.findOne({
      where: {
        session_token: oldToken,
        account_id: decoded.userId,
        is_active: true,
      },
    });

    if (!session) {
      return res.status(401).json({ error: 'Session not found' });
    }

    // Generate new token
    const newToken = jwt.sign({ userId: session.account_id }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRE || '7d',
    });

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    // Update session with new token
    session.session_token = newToken;
    session.expires_at = expiresAt;
    await session.save();

    res.json({
      success: true,
      data: {
        token: newToken,
        expiresAt,
      },
    });
  } catch (error) {
    next(error);
  }
};
