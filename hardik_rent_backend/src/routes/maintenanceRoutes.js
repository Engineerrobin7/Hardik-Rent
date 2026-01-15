const express = require('express');
const router = express.Router();
const maintenanceController = require('../controllers/maintenanceController');

router.post('/tickets', maintenanceController.createTicket);
router.patch('/tickets/status', maintenanceController.updateTicketStatus);
router.get('/tenant', maintenanceController.getTenantTickets);
router.get('/owner', maintenanceController.getOwnerTickets);

module.exports = router;
