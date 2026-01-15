const { messaging } = require('../config/firebaseAdmin');
const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

exports.createTicket = async (req, res) => {
    try {
        const { title, description, priority, unitId, photoUrl } = req.body;
        const tenantId = req.user.uid;
        const ticketId = uuidv4();

        // 1. Insert into MySQL
        const query = `
            INSERT INTO maintenance_requests (id, unit_id, tenant_id, title, description, priority, status, photo_url)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;
        await db.execute(query, [ticketId, unitId, tenantId, title, description, priority || 'medium', 'open', photoUrl || null]);

        // 2. Notify Owner (Fetch FCM Token)
        const [ownerRows] = await db.query(`
            SELECT u.fcm_token 
            FROM users u
            JOIN properties p ON u.id = p.owner_id
            JOIN units un ON p.id = un.property_id
            WHERE un.id = ?
        `, [unitId]);

        if (ownerRows.length > 0 && ownerRows[0].fcm_token) {
            const message = {
                notification: {
                    title: 'New Maintenance Request',
                    body: `New request for unit ${unitId}: ${title}`
                },
                token: ownerRows[0].fcm_token
            };
            try {
                await messaging.send(message);
            } catch (err) {
                console.warn('FCM delivery failed:', err.message);
            }
        }

        res.status(201).json({ id: ticketId, message: 'Ticket created successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.updateTicketStatus = async (req, res) => {
    try {
        const { ticketId, status, notes, cost } = req.body;

        // 1. Update MySQL
        const query = `
            UPDATE maintenance_requests 
            SET status = ?, resolution_notes = ?, cost = ?
            WHERE id = ?
        `;
        await db.execute(query, [status, notes || null, cost || null, ticketId]);

        // 2. Notify Tenant
        const [tenantRows] = await db.query(`
            SELECT u.fcm_token, m.title 
            FROM users u
            JOIN maintenance_requests m ON u.id = m.tenant_id
            WHERE m.id = ?
        `, [ticketId]);

        if (tenantRows.length > 0 && tenantRows[0].fcm_token) {
            const message = {
                notification: {
                    title: 'Maintenance Update',
                    body: `Your request "${tenantRows[0].title}" is now ${status}.`
                },
                token: tenantRows[0].fcm_token
            };
            try {
                await messaging.send(message);
            } catch (err) {
                console.warn('FCM delivery failed:', err.message);
            }
        }

        res.status(200).json({ message: 'Ticket updated successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.getTenantTickets = async (req, res) => {
    try {
        const tenantId = req.user.uid;
        const [rows] = await db.query('SELECT * FROM maintenance_requests WHERE tenant_id = ?', [tenantId]);
        res.status(200).json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.getOwnerTickets = async (req, res) => {
    try {
        const ownerId = req.user.uid;
        const [rows] = await db.query(`
            SELECT m.*, u.unit_number, p.name as propertyName
            FROM maintenance_requests m
            JOIN units u ON m.unit_id = u.id
            JOIN properties p ON u.property_id = p.id
            WHERE p.owner_id = ?
        `, [ownerId]);
        res.status(200).json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
