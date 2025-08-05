/**
 * User Routes - Handle user profile and account management
 * YTEmpire Project
 */

const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authorizeRole } = require('../middleware/auth');

/**
 * @route   GET /api/users
 * @desc    Get all users (admin only)
 * @access  Private/Admin
 */
router.get('/', authorizeRole('admin'), userController.getAll);

/**
 * @route   GET /api/users/:id
 * @desc    Get user by ID
 * @access  Private
 */
router.get('/:id', userController.getById);

/**
 * @route   PUT /api/users/:id
 * @desc    Update user profile
 * @access  Private (own profile or admin)
 */
router.put('/:id', userController.update);

/**
 * @route   PUT /api/users/settings
 * @desc    Update user settings (own account only)
 * @access  Private
 */
router.put('/settings', userController.updateSettings);

/**
 * @route   DELETE /api/users/:id
 * @desc    Delete user account (admin only)
 * @access  Private/Admin
 */
router.delete('/:id', authorizeRole('admin'), userController.delete);

module.exports = router;
