const express = require('express');
const router = express.Router();
const expenseController = require('../controllers/expenseController');
const notificationController = require('../controllers/notificationController');
const staffController = require('../controllers/staffController');
const handoverController = require('../controllers/handoverController');
const kycController = require('../controllers/kycController');
const { verifyToken } = require('../middleware/auth');

// Expense Tracker
router.post('/expenses', verifyToken, expenseController.addExpense);
router.get('/expenses', verifyToken, expenseController.getOwnerExpenses);
router.delete('/expenses/:id', verifyToken, expenseController.deleteExpense);

// Broadcasting Notifications
router.post('/notifications/broadcast', verifyToken, notificationController.broadcastToProperty);

// Staff Management
router.post('/staff', verifyToken, staffController.addStaff);
router.get('/staff', verifyToken, staffController.getOwnerStaff);

// Handover / Inventory Check
router.post('/handovers', verifyToken, handoverController.createHandover);
router.get('/handovers/unit/:unitId', verifyToken, handoverController.getUnitHistory);

// KYC
router.post('/kyc/aadhaar/initiate', verifyToken, kycController.initiateAadhaarOtp);
router.post('/kyc/aadhaar/verify', verifyToken, kycController.verifyAadhaarOtp);
router.post('/kyc/submit', verifyToken, kycController.submitKyc);
router.post('/kyc/verify', verifyToken, kycController.verifyKyc);

module.exports = router;
