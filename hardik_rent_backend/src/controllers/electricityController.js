const { db, messaging } = require('../config/firebaseAdmin');

/**
 * Mock function to simulate fetching bill details from a State Electricity Board API.
 * In a real scenario, you would use axios/node-fetch to hit a BBPS or State Board API.
 */
const mockFetchFromElectricityBoard = async (consumerNumber, state) => {
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 800));

    // Logic: If consumer number ends in even digit, consider it PAID. If odd, UNPAID.
    // This allows for predictable testing for the user.
    const lastDigit = parseInt(consumerNumber.slice(-1));
    const isPaid = lastDigit % 2 === 0;

    return {
        consumerNumber,
        state,
        billAmount: (Math.random() * 2000 + 500).toFixed(2),
        dueDate: new Date(Date.now() + 86400000 * 5).toISOString(),
        status: isPaid ? 'PAID' : 'UNPAID',
        lastPaymentDate: isPaid ? new Date().toISOString() : null
    };
};

exports.checkElectricityStatus = async (req, res) => {
    try {
        const { propertyId, unitId } = req.params;

        const unitDoc = await db.collection('properties').doc(propertyId)
            .collection('units').doc(unitId).get();

        if (!unitDoc.exists) {
            return res.status(404).json({ error: 'Unit not found' });
        }

        const unit = unitDoc.data();
        const consumerNumber = unit.electricityConsumerNumber || `100200300${unit.unitNumber}`;
        const state = unit.state || 'Maharashtra'; // Default state

        const billDetails = await mockFetchFromElectricityBoard(consumerNumber, state);

        res.status(200).json({
            unitId,
            propertyId,
            unitNumber: unit.unitNumber,
            billDetails
        });
    } catch (error) {
        console.error('Check Electricity Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.toggleElectricityWithRule = async (req, res) => {
    try {
        const { propertyId, unitId, enabled } = req.body;
        const ownerId = req.user.uid;

        // 1. Verify Ownership
        const propertyDoc = await db.collection('properties').doc(propertyId).get();
        if (!propertyDoc.exists || propertyDoc.data().ownerId !== ownerId) {
            return res.status(403).json({ error: 'Unauthorized to toggle electricity for this property' });
        }

        const unitRef = db.collection('properties').doc(propertyId).collection('units').doc(unitId);
        const unitDoc = await unitRef.get();

        if (!unitDoc.exists) {
            return res.status(404).json({ error: 'Unit not found' });
        }

        const unit = unitDoc.data();

        // 2. Fetch Live Bill Status
        const consumerNumber = unit.electricityConsumerNumber || `100200300${unit.unitNumber}`;
        const bill = await mockFetchFromElectricityBoard(consumerNumber, unit.state || 'Maharashtra');

        // 3. Apply Business Logic: Allow "Turn On" only if bill is PAID
        if (enabled && bill.status !== 'PAID') {
            return res.status(400).json({
                error: 'Action Denied',
                message: 'Cannot turn on electricity. The tenant has an unpaid bill of ₹' + bill.billAmount,
                billDetails: bill
            });
        }

        // 4. Perform Toggle
        await unitRef.update({
            'isElectricityActive': enabled, // Matches Flutter model key
            'electricity.enabled': enabled, // Matches old backend key for compatibility
            'electricity.lastStatusCheck': new Date().toISOString(),
            'electricity.billStatus': bill.status,
            'updatedAt': new Date().toISOString()
        });

        // 5. Notify Tenant
        try {
            if (unit.tenantId) {
                const tenantDoc = await db.collection('users').doc(unit.tenantId).get();
                if (tenantDoc.exists && tenantDoc.data().fcmToken) {
                    await messaging.send({
                        notification: {
                            title: enabled ? '⚡ Electricity Restored' : '🔌 Electricity Cut-off',
                            body: enabled
                                ? 'Your electricity has been turned on as the bill is paid.'
                                : 'Your electricity was cut off by the owner due to unpaid bills.'
                        },
                        token: tenantDoc.data().fcmToken
                    });
                }
            }
        } catch (fcmErr) {
            console.warn('FCM Notification error:', fcmErr.message);
        }

        res.status(200).json({
            message: `Electricity ${enabled ? 'enabled' : 'disabled'} successfully`,
            billStatus: bill.status
        });
    } catch (error) {
        console.error('Toggle Electricity Rule Error:', error);
        res.status(500).json({ error: error.message });
    }
};
