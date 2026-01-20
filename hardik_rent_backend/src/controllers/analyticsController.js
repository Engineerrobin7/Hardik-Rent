const { db } = require('../config/firebaseAdmin');

exports.getFinancialSummary = async (req, res) => {
    try {
        const ownerId = req.user.uid;

        // 1. Fetch all properties owned by this user
        const propertiesSnapshot = await db.collection('properties').where('ownerId', '==', ownerId).get();

        let totalRevenue = 0;
        let totalUnits = 0;
        let occupiedUnits = 0;
        let pendingRent = 0;

        // 2. Iterate through each property and its units
        for (const propertyDoc of propertiesSnapshot.docs) {
            const propertyId = propertyDoc.id;
            const unitsSnapshot = await db.collection('properties').doc(propertyId).collection('units').get();

            unitsSnapshot.forEach(unitDoc => {
                const unit = unitDoc.data();
                totalUnits++;

                if (unit.status === 'occupied') {
                    occupiedUnits++;
                    totalRevenue += Number(unit.rent) || 0;
                }
            });
        }

        // 3. Pending Rent Calculation
        // In this Firestore schema, pending rent would ideally be in a 'payments' collection
        const paymentsSnapshot = await db.collection('payments')
            .where('ownerId', '==', ownerId)
            .where('status', '==', 'pending')
            .get();

        paymentsSnapshot.forEach(paymentDoc => {
            pendingRent += Number(paymentDoc.data().amount) || 0;
        });

        const occupancyRate = totalUnits > 0 ? (occupiedUnits / totalUnits) * 100 : 0;

        res.status(200).json({
            totalRevenue,
            occupancyRate: occupancyRate.toFixed(2),
            pendingRent,
            stats: {
                totalUnits,
                occupiedUnits,
                vacantUnits: totalUnits - occupiedUnits
            }
        });
    } catch (error) {
        console.error('Analytics Error:', error);
        res.status(500).json({ error: error.message });
    }
};
