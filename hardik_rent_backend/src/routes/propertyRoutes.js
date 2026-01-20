const express = require('express');
const router = express.Router();
const propertyController = require('../controllers/propertyController');
const { body, validationResult } = require('express-validator');

// Validation middleware
const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    next();
};

router.get('/', propertyController.getOwnerProperties);
router.get('/all', propertyController.getAllProperties);
router.get('/my-unit', propertyController.getTenantProperty);

router.post('/', [
    body('name').notEmpty().withMessage('Property name is required'),
    body('address').notEmpty().withMessage('Address is required'),
    body('type').notEmpty().withMessage('Property type is required'),
    validate
], propertyController.createProperty);

router.post('/unit', [
    body('propertyId').notEmpty().withMessage('Property ID is required'),
    body('unitNumber').notEmpty().withMessage('Unit number is required'),
    body('rent').isNumeric().withMessage('Rent must be a number'),
    body('type').notEmpty().withMessage('Unit type is required'),
    validate
], propertyController.createUnit);

router.patch('/unit-status', [
    body('propertyId').notEmpty().withMessage('Property ID is required'),
    body('unitId').notEmpty().withMessage('Unit ID is required'),
    body('status').isIn(['vacant', 'occupied', 'under_maintenance']).withMessage('Invalid status'),
    validate
], propertyController.updateUnitStatus);

router.patch('/toggle-electricity', [
    body('propertyId').notEmpty().withMessage('Property ID is required'),
    body('unitId').notEmpty().withMessage('Unit ID is required'),
    body('enabled').isBoolean().withMessage('Enabled must be a boolean'),
    validate
], propertyController.toggleElectricity);

module.exports = router;
