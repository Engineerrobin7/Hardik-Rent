const { messaging, db } = require('../config/firebaseAdmin');
const { v4: uuidv4 } = require('uuid');

exports.createTicket = async (req, res) => {
    try {
        const { title, description, priority, unitId, propertyId, photoUrl } = req.body;
        const tenantId = req.user.uid;

        if (!title || !unitId || !propertyId) {
            return res.status(400).json({ error: 'Missing required fields: title, unitId, propertyId' });
        }

        const ticketId = uuidv4();
        const ticketData = {
            id: ticketId,
            title,
            description: description || '',
            priority: priority || 'medium',
            unitId,
            propertyId,
            tenantId,
            photoUrl: photoUrl || null,
            status: 'pending',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        await db.collection('maintenance_tickets').doc(ticketId).set(ticketData);

        // Fetch owner's FCM token to notify them
        try {
            const propertyDoc = await db.collection('properties').doc(propertyId).get();
            if (propertyDoc.exists) {
                const ownerId = propertyDoc.data().ownerId;
                const ownerDoc = await db.collection('users').doc(ownerId).get();
                if (ownerDoc.exists && ownerDoc.data().fcmToken) {
                    await messaging.send({
                        notification: {
                            title: '🛠️ New Maintenance Request',
                            body: `Unit ${unitId}: ${title}`
                        },
                        token: ownerDoc.data().fcmToken
                    });
                }
            }
        } catch (fcmErr) {
            console.warn('FCM Notification error:', fcmErr.message);
        }

        res.status(201).json({ message: 'Ticket created successfully', ticketId });
    } catch (error) {
        console.error('Create Ticket Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.updateTicketStatus = async (req, res) => {
    try {
        const { ticketId, status, notes } = req.body;

        if (!ticketId || !status) {
            return res.status(400).json({ error: 'Ticket ID and status are required' });
        }

        const ticketRef = db.collection('maintenance_tickets').doc(ticketId);
        const ticketDoc = await ticketRef.get();

        if (!ticketDoc.exists) {
            return res.status(404).json({ error: 'Ticket not found' });
        }

        await ticketRef.update({
            status,
            notes: notes || '',
            updatedAt: new Date().toISOString()
        });

        // Notify tenant
        try {
            const tenantId = ticketDoc.data().tenantId;
            const tenantDoc = await db.collection('users').doc(tenantId).get();
            if (tenantDoc.exists && tenantDoc.data().fcmToken) {
                await messaging.send({
                    notification: {
                        title: '🔧 Maintenance Update',
                        body: `Your request "${ticketDoc.data().title}" is now ${status}.`
                    },
                    token: tenantDoc.data().fcmToken
                });
            }
        } catch (fcmErr) {
            console.warn('FCM Notification error:', fcmErr.message);
        }

        res.status(200).json({ message: 'Ticket updated successfully' });
    } catch (error) {
        console.error('Update Ticket Status Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.getTenantTickets = async (req, res) => {
    try {
        const tenantId = req.user.uid;
        const snapshot = await db.collection('maintenance_tickets')
            .where('tenantId', '==', tenantId)
            .orderBy('createdAt', 'desc')
            .get();

        const tickets = snapshot.docs.map(doc => doc.data());
        res.status(200).json(tickets);
    } catch (error) {
        console.error('Get Tenant Tickets Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.getOwnerTickets = async (req, res) => {
    try {
        const ownerId = req.user.uid;
        // Owners see tickets for all properties they own
        const propertiesSnapshot = await db.collection('properties')
            .where('ownerId', '==', ownerId)
            .get();

        const propertyIds = propertiesSnapshot.docs.map(doc => doc.id);

        if (propertyIds.length === 0) {
            return res.status(200).json([]);
        }

        // Firestore 'in' query has a limit of 10 items, but for many owners this is enough.
        // For larger scales, you'd store ownerId directly in the ticket.
        const snapshot = await db.collection('maintenance_tickets')
            .where('propertyId', 'in', propertyIds)
            .orderBy('createdAt', 'desc')
            .get();

        const tickets = snapshot.docs.map(doc => doc.data());
        res.status(200).json(tickets);
    } catch (error) {
        console.error('Get Owner Tickets Error:', error);
        res.status(500).json({ error: error.message });
    }
};


