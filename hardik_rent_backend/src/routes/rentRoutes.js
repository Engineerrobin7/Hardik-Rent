const express = require('express');
const router = express.Router();
const rentController = require('../controllers/rentController');
const { verifyToken } = require('../middleware/auth');

router.get('/tenant', verifyToken, rentController.getTenantRentRecords);
router.get('/owner', verifyToken, rentController.getOwnerRentRecords);
router.post('/generate', verifyToken, rentController.generateMonthlyRent);

module.exports = router;
