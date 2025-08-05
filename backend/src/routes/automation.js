/**
 * Automation Routes - Handle automation workflows and scheduled tasks
 * YTEmpire Project
 */

const express = require('express');
const router = express.Router();
const automationController = require('../controllers/automationController');
// TODO: Uncomment when authentication is implemented on routes
// const { authenticateToken } = require('../middleware/auth');
const { validate } = require('../middleware/validation');

// TODO: Define routes

// Example routes
router.get('/', automationController.getAll);
router.post('/', validate('create'), automationController.create);
router.get('/:id', automationController.getById);
router.put('/:id', validate('update'), automationController.update);
router.delete('/:id', automationController.delete);

module.exports = router;
