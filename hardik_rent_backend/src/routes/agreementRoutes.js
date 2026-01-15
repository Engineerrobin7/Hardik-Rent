const express = require('express');
const router = express.Router();
const agreementController = require('../controllers/agreementController');
const { verifyToken } = require('../middleware/auth');

router.post('/', verifyToken, agreementController.uploadAgreement);
router.get('/unit/:unitId', verifyToken, agreementController.getAgreementsByUnit);
router.get('/my-agreements', verifyToken, agreementController.getTenantAgreements);

module.exports = router;
