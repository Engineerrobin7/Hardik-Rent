const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
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

router.post('/create-order', verifyToken, [
    body('amount').isNumeric().withMessage('Amount must be a number'),
    body('unitId').notEmpty().withMessage('Unit ID is required'),
    validate
], paymentController.createOrder);

router.post('/verify', verifyToken, [
    body('razorpay_order_id').notEmpty().withMessage('Order ID is required'),
    body('razorpay_payment_id').notEmpty().withMessage('Payment ID is required'),
    body('razorpay_signature').notEmpty().withMessage('Signature is required'),
    validate
], paymentController.verifyPayment);

module.exports = router;
