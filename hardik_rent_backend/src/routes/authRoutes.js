const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { verifyToken } = require('../middleware/auth');

router.post('/register', authController.registerUser);
router.post('/fcm-token', verifyToken, authController.updateFcmToken);
router.post('/sync', verifyToken, authController.syncUser);


// Get current user profile
router.get('/me', verifyToken, authController.getUser);
router.post('/create-tenant', verifyToken, authController.createTenant);

module.exports = router;
