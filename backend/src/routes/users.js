/**
 * User Routes - Handle user profile and account management
 * YTEmpire Project
 */

const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateToken } = require('../middleware/auth');
const { validate } = require('../middleware/validation');

// TODO: Define routes

// Example routes
router.get('/', userController.getAll);
router.post('/', validate('create'), userController.create);
router.get('/:id', userController.getById);
router.put('/:id', validate('update'), userController.update);
router.delete('/:id', userController.delete);

module.exports = router;