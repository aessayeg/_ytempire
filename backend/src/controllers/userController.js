/**
 * UserController - User management controller
 * YTEmpire Project
 */

const { User, Profile, Channel } = require('../models');
const { Op } = require('sequelize');

/**
 * Get all users (admin only)
 */
exports.getAll = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, accountType, status } = req.query;
    const offset = (page - 1) * limit;

    // Build where clause
    const where = {};
    if (search) {
      where[Op.or] = [
        { email: { [Op.iLike]: `%${search}%` } },
        { username: { [Op.iLike]: `%${search}%` } },
      ];
    }
    if (accountType) where.account_type = accountType;
    if (status) where.account_status = status;

    const { count, rows } = await User.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      attributes: { exclude: ['password_hash'] },
      include: [
        {
          model: Profile,
          as: 'profile',
          attributes: ['display_name', 'avatar_url'],
        },
      ],
      order: [['created_at', 'DESC']],
    });

    res.json({
      success: true,
      data: {
        users: rows,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(count / limit),
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get user by ID
 */
exports.getById = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.params.id, {
      attributes: { exclude: ['password_hash'] },
      include: [
        {
          model: Profile,
          as: 'profile',
        },
        {
          model: Channel,
          as: 'channels',
          attributes: ['channel_id', 'channel_name', 'youtube_channel_id', 'subscriber_count'],
        },
      ],
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update user profile
 */
exports.update = async (req, res, next) => {
  try {
    const userId = req.params.id;

    // Only allow users to update their own profile unless admin
    if (req.user.account_id !== userId && req.user.account_type !== 'admin') {
      return res.status(403).json({ error: 'Unauthorized to update this profile' });
    }

    const {
      firstName,
      lastName,
      displayName,
      bio,
      avatarUrl,
      timezone,
      language,
      companyName,
      websiteUrl,
    } = req.body;

    // Update profile
    const profile = await Profile.findOne({
      where: { account_id: userId },
    });

    if (!profile) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    await profile.update({
      first_name: firstName !== undefined ? firstName : profile.first_name,
      last_name: lastName !== undefined ? lastName : profile.last_name,
      display_name: displayName || profile.display_name,
      bio: bio !== undefined ? bio : profile.bio,
      avatar_url: avatarUrl !== undefined ? avatarUrl : profile.avatar_url,
      timezone: timezone || profile.timezone,
      language: language || profile.language,
      company_name: companyName !== undefined ? companyName : profile.company_name,
      website_url: websiteUrl !== undefined ? websiteUrl : profile.website_url,
    });

    // Get updated user with profile
    const updatedUser = await User.findByPk(userId, {
      attributes: { exclude: ['password_hash'] },
      include: [
        {
          model: Profile,
          as: 'profile',
        },
      ],
    });

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: updatedUser,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update user settings (own account only)
 */
exports.updateSettings = async (req, res, next) => {
  try {
    const userId = req.user.account_id;
    const { email, username, twoFactorEnabled } = req.body;

    const user = await User.findByPk(userId);

    // Check if email/username already taken
    if (email && email !== user.email) {
      const existingEmail = await User.findOne({ where: { email } });
      if (existingEmail) {
        return res.status(409).json({ error: 'Email already in use' });
      }
    }

    if (username && username !== user.username) {
      const existingUsername = await User.findOne({ where: { username } });
      if (existingUsername) {
        return res.status(409).json({ error: 'Username already taken' });
      }
    }

    // Update user
    await user.update({
      email: email || user.email,
      username: username || user.username,
      two_factor_enabled:
        twoFactorEnabled !== undefined ? twoFactorEnabled : user.two_factor_enabled,
    });

    // Profile preferences removed - not in current schema

    const updatedUser = await User.findByPk(userId, {
      attributes: { exclude: ['password_hash'] },
      include: [
        {
          model: Profile,
          as: 'profile',
        },
      ],
    });

    res.json({
      success: true,
      message: 'Settings updated successfully',
      data: updatedUser,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete user account (admin only)
 */
exports.delete = async (req, res, next) => {
  try {
    const userId = req.params.id;

    // Prevent self-deletion
    if (req.user.account_id === userId) {
      return res.status(400).json({ error: 'Cannot delete your own account' });
    }

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Soft delete by changing status
    await user.update({ account_status: 'suspended' });

    res.json({
      success: true,
      message: 'User account suspended successfully',
    });
  } catch (error) {
    next(error);
  }
};
