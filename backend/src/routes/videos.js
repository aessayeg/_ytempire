/**
 * Video Routes - Handle video upload, management and metadata operations
 * YTEmpire Project
 */

const express = require('express');
const router = express.Router();
const videoController = require('../controllers/videoController');
const { authenticateToken } = require('../middleware/auth');
const { validate } = require('../middleware/validation');

// TODO: Define routes

// Example routes
router.get('/', videoController.getAll);
router.post('/', validate('create'), videoController.create);
router.get('/:id', videoController.getById);
router.put('/:id', validate('update'), videoController.update);
router.delete('/:id', videoController.delete);

module.exports = router;