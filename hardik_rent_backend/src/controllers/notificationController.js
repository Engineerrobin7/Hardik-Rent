const { messaging, db } = require('../config/firebaseAdmin');

exports.broadcastToProperty = async (req, res) => {
    try {
        const { propertyId, title, message } = req.body;
        const ownerId = req.user.uid;

        if (!propertyId || !title || !message) {
            return res.status(400).json({ error: 'Missing propertyId, title, or message' });
        }

        // 1. Verify Ownership
        const propertyDoc = await db.collection('properties').doc(propertyId).get();
        if (!propertyDoc.exists || propertyDoc.data().ownerId !== ownerId) {
            return res.status(403).json({ error: 'Unauthorized to broadcast to this property' });
        }

        // 2. Fetch all tenants for this property
        const tenantsSnapshot = await db.collection('users')
            .where('propertyId', '==', propertyId)
            .where('role', '==', 'tenant')
            .get();

        const tokens = tenantsSnapshot.docs
            .map(doc => doc.data().fcmToken)
            .filter(token => token != null);

        if (tokens.length === 0) {
            return res.status(200).json({ message: 'No active tenants with FCM tokens found' });
        }

        // 3. Send Multicast Message
        const response = await messaging.sendEachForMulticast({
            tokens: tokens,
            notification: {
                title: `📢 ${title}`,
                body: message
            },
            data: {
                propertyId: propertyId,
                type: 'broadcast'
            }
        });

        res.status(200).json({
            message: 'Broadcast sent successfully',
            successCount: response.successCount,
            failureCount: response.failureCount
        });
    } catch (error) {
        console.error('Broadcast Error:', error);
        res.status(500).json({ error: error.message });
    }
};
