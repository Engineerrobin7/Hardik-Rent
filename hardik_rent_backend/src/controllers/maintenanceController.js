const { messaging, db } = require('../config/firebaseAdmin');
const { v4: uuidv4 } = require('uuid');

exports.createTicket = async (req, res) => {
    try {
        const { title, description, priority, unitId, photoUrl, tenantId } = req.body;
        // The actual ticket creation in Firestore will be handled by the Flutter app.
        // This backend endpoint's primary role is to send notifications.

        // TODO: Fetch owner's FCM token from Firestore based on unitId
        // This will require querying Firestore for property -> owner -> owner's FCM token.
        let ownerFcmToken = null; // Placeholder for FCM token

        // Example Firestore query to get owner's FCM token:
        // Assuming 'maintenance_requests' collection where each request has a 'unitId'.
        // And 'units' collection where each unit has a 'propertyId'.
        // And 'properties' collection where each property has an 'ownerId'.
        // And 'users' collection where each user has an 'fcmToken'.
        //
        // This is a simplified example and might need adjustment based on actual Firestore structure.
        //
        // const unitDoc = await db.collection('units').doc(unitId).get();
        // if (unitDoc.exists && unitDoc.data().propertyId) {
        //     const propertyDoc = await db.collection('properties').doc(unitDoc.data().propertyId).get();
        //     if (propertyDoc.exists && propertyDoc.data().ownerId) {
        //         const ownerDoc = await db.collection('users').doc(propertyDoc.data().ownerId).get();
        //         if (ownerDoc.exists && ownerDoc.data().fcmToken) {
        //             ownerFcmToken = ownerDoc.data().fcmToken;
        //         }
        //     }
        // }


        if (ownerFcmToken) {
            const message = {
                notification: {
                    title: 'New Maintenance Request',
                    body: `New request for unit ${unitId}: ${title}`
                },
                token: ownerFcmToken
            };
            try {
                await messaging.send(message);
            } catch (err) {
                console.warn('FCM delivery failed:', err.message);
            }
        }

        res.status(201).json({ message: 'Notification triggered for new ticket' });
    } catch (error) {
        console.error('Create Ticket Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.updateTicketStatus = async (req, res) => {
    try {
        const { ticketId, status, notes, cost } = req.body;

        // The actual ticket status update in Firestore will be handled by the Flutter app.
        // This backend endpoint's primary role is to send notifications.

        // TODO: Fetch tenant's FCM token from Firestore based on ticketId
        // This will require querying Firestore for maintenance request -> tenant -> tenant's FCM token.
        let tenantFcmToken = null; // Placeholder for FCM token
        let ticketTitle = "Maintenance Request"; // Placeholder for title

        // Example Firestore query:
        // const ticketDoc = await db.collection('maintenance_requests').doc(ticketId).get();
        // if (ticketDoc.exists && ticketDoc.data().tenantId) {
        //     ticketTitle = ticketDoc.data().title || ticketTitle;
        //     const tenantId = ticketDoc.data().tenantId;
        //     const tenantDoc = await db.collection('users').doc(tenantId).get();
        //     if (tenantDoc.exists && tenantDoc.data().fcmToken) {
        //         tenantFcmToken = tenantDoc.data().fcmToken;
        //     }
        // }

        if (tenantFcmToken) {
            const message = {
                notification: {
                    title: 'Maintenance Update',
                    body: `Your request "${ticketTitle}" is now ${status}.`
                },
                token: tenantFcmToken
            };
            try {
                await messaging.send(message);
            } catch (err) {
                console.warn('FCM delivery failed:', err.message);
            }
        }

        res.status(200).json({ message: 'Notification triggered for ticket status update' });
    } catch (error) {
        console.error('Update Ticket Status Error:', error);
        res.status(500).json({ error: error.message });
    }
};


