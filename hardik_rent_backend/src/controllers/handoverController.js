const { db } = require('../config/firebaseAdmin');
const { v4: uuidv4 } = require('uuid');

exports.createHandover = async (req, res) => {
    try {
        const { propertyId, unitId, tenantId, type, checklist, photos } = req.body;
        const ownerId = req.user.uid;

        if (!propertyId || !unitId || !type) {
            return res.status(400).json({ error: 'Missing unitId or type (check-in/check-out)' });
        }

        const handoverId = uuidv4();
        const handoverData = {
            id: handoverId,
            propertyId,
            unitId,
            tenantId,
            type, // 'check-in' or 'check-out'
            checklist: checklist || [], // e.g. [{item: 'Walls', state: 'Clean', comments: ''}]
            photos: photos || [], // Array of URLs
            checkedBy: ownerId,
            date: new Date().toISOString(),
            status: 'completed'
        };

        await db.collection('handovers').doc(handoverId).set(handoverData);

        res.status(201).json({ message: 'Handover report saved', handoverId });
    } catch (error) {
        console.error('Handover Error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.getUnitHistory = async (req, res) => {
    try {
        const { unitId } = req.params;
        const snapshot = await db.collection('handovers')
            .where('unitId', '==', unitId)
            .orderBy('date', 'desc')
            .get();

        const history = snapshot.docs.map(doc => doc.data());
        res.status(200).json(history);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
