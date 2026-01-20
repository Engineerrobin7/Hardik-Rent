const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { verifyToken } = require('../middleware/auth');
const { body, validationResult } = require('express-validator');

// Validation middleware
const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    next();
};

router.post('/register', [
    body('email').isEmail().withMessage('Enter a valid email'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('role').isIn(['owner', 'tenant', 'admin']).withMessage('Invalid role'),
    body('displayName').notEmpty().withMessage('Display name is required'),
    validate
], authController.registerUser);

router.post('/fcm-token', verifyToken, [
    body('fcmToken').notEmpty().withMessage('FCM token is required'),
    validate
], authController.updateFcmToken);

router.post('/sync', verifyToken, authController.syncUser);

// Get current user profile
router.get('/me', verifyToken, authController.getUser);

router.post('/create-tenant', verifyToken, [
    body('email').isEmail().withMessage('Enter a valid email'),
    body('displayName').notEmpty().withMessage('Display name is required'),
    body('phoneNumber').notEmpty().withMessage('Phone number is required'),
    validate
], authController.createTenant);

module.exports = router;
