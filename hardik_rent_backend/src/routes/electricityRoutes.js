const express = require('express');
const router = express.Router();
const electricityController = require('../controllers/electricityController');
const { verifyToken } = require('../middleware/auth');

// Get real-time bill status from external board (mocked)
router.get('/status/:propertyId/:unitId', verifyToken, electricityController.checkElectricityStatus);

// Toggle electricity with payment verification rule
router.post('/toggle', verifyToken, electricityController.toggleElectricityWithRule);

module.exports = router;
