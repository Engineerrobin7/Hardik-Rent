const { db } = require('../config/firebaseAdmin');
const { v4: uuidv4 } = require('uuid');

exports.getTenantRentRecords = async (req, res) => {
    try {
        const tenantId = req.user.uid;
        const snapshot = await db.collection('rent_records')
            .where('tenantId', '==', tenantId)
            .orderBy('dueDate', 'desc')
            .get();

        const records = snapshot.docs.map(doc => doc.data());
        res.status(200).json(records);
    } catch (error) {
        console.error('Get Tenant Rent Records Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.getOwnerRentRecords = async (req, res) => {
    try {
        const ownerId = req.user.uid;

        // Find properties for this owner
        const propsSnapshot = await db.collection('properties')
            .where('ownerId', '==', ownerId)
            .get();

        const propertyIds = propsSnapshot.docs.map(doc => doc.id);
        if (propertyIds.length === 0) return res.status(200).json([]);

        // Fetch rent records for these properties
        // Using propertyId if stored in rent_record, or filtering by unitIds
        const snapshot = await db.collection('rent_records')
            .where('propertyId', 'in', propertyIds)
            .orderBy('dueDate', 'desc')
            .get();

        const records = snapshot.docs.map(doc => doc.data());
        res.status(200).json(records);
    } catch (error) {
        console.error('Get Owner Rent Records Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.generateMonthlyRent = async (req, res) => {
    try {
        const { propertyId, month, dueDate } = req.body;
        const ownerId = req.user.uid;

        if (!propertyId || !month || !dueDate) {
            return res.status(400).json({ error: 'Missing propertyId, month, or dueDate' });
        }

        // 1. Verify ownership
        const propDoc = await db.collection('properties').doc(propertyId).get();
        if (!propDoc.exists || propDoc.data().ownerId !== ownerId) {
            return res.status(403).json({ error: 'Unauthorized cover for this property' });
        }

        // 2. Get all occupied units
        const unitsSnapshot = await db.collection('properties').doc(propertyId)
            .collection('units')
            .where('status', '==', 'occupied')
            .get();

        const batch = db.batch();
        const createdCount = 0;

        for (const unitDoc of unitsSnapshot.docs) {
            const unit = unitDoc.data();
            const rentId = uuidv4();

            // Avoid duplicate for same month/unit
            const existing = await db.collection('rent_records')
                .where('unitId', '==', unit.id)
                .where('month', '==', month)
                .get();

            if (existing.empty) {
                const rentData = {
                    id: rentId,
                    propertyId,
                    unitId: unit.id,
                    unitNumber: unit.unitNumber,
                    tenantId: unit.tenantId,
                    month,
                    baseRent: Number(unit.rent),
                    amountPaid: 0,
                    status: 'pending',
                    dueDate,
                    generatedAt: new Date().toISOString()
                };
                const ref = db.collection('rent_records').doc(rentId);
                batch.set(ref, rentData);
            }
        }

        await batch.commit();

        res.status(201).json({ message: 'Rent records generated successfully' });
    } catch (error) {
        console.error('Generate Rent Error:', error);
        res.status(500).json({ error: error.message });
    }
};
