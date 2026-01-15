const express = require('express');
const router = express.Router();
const propertyController = require('../controllers/propertyController');

router.get('/', propertyController.getOwnerProperties);
router.post('/', propertyController.createProperty);
router.patch('/unit-status', propertyController.updateUnitStatus);

module.exports = router;
