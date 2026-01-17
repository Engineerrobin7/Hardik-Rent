const express = require('express');
const router = express.Router();
const propertyController = require('../controllers/propertyController');

router.get('/', propertyController.getOwnerProperties);
router.post('/', propertyController.createProperty);
router.post('/unit', propertyController.createUnit);
router.patch('/unit-status', propertyController.updateUnitStatus);
router.patch('/toggle-electricity', propertyController.toggleElectricity);

module.exports = router;
