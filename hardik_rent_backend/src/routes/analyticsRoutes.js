const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');
const { verifyToken } = require('../middleware/auth');

router.get('/summary', verifyToken, analyticsController.getFinancialSummary);

module.exports = router;
