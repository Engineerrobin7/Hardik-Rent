const { db } = require('../config/firebaseAdmin');
const { v4: uuidv4 } = require('uuid');

/**
 * Creates a new agreement and stores it in Firestore.
 * Requires propertyId to be passed in the body to facilitate lookups.
 */
exports.uploadAgreement = async (req, res) => {
    try {
        const { unitId, tenantId, propertyId, pdfUrl, startDate, endDate } = req.body;
        const ownerId = req.user.uid;

        if (!unitId || !tenantId || !propertyId || !pdfUrl || !startDate || !endDate) {
            return res.status(400).json({ error: 'Missing required fields.' });
        }

        const id = uuidv4();

        const agreementData = {
            id,
            unitId,
            tenantId,
            propertyId, // Storing for easier lookup
            ownerId,
            pdfUrl,
            startDate,
            endDate,
            createdAt: new Date().toISOString(),
        };

        await db.collection('agreements').doc(id).set(agreementData);

        res.status(201).json({ id, message: 'Agreement uploaded successfully' });
    } catch (error) {
        console.error("Error uploading agreement:", error);
        res.status(500).json({ error: error.message });
    }
};

/**
 * Retrieves all agreements for a specific unit.
 */
exports.getAgreementsByUnit = async (req, res) => {
    try {
        const { unitId } = req.params;
        const agreementsSnapshot = await db.collection('agreements').where('unitId', '==', unitId).get();

        if (agreementsSnapshot.empty) {
            return res.status(200).json([]);
        }

        const agreements = agreementsSnapshot.docs.map(doc => doc.data());
        res.status(200).json(agreements);
    } catch (error) {
        console.error("Error getting agreements by unit:", error);
        res.status(500).json({ error: error.message });
    }
};

/**
 * Retrieves all agreements for the currently authenticated tenant,
 * and enriches them with property and unit details.
 */
exports.getTenantAgreements = async (req, res) => {
    try {
        const tenantId = req.user.uid;
        const agreementsSnapshot = await db.collection('agreements').where('tenantId', '==', tenantId).get();

        if (agreementsSnapshot.empty) {
            return res.status(200).json([]);
        }

        // Use Promise.all to fetch related data in parallel
        const agreementsPromises = agreementsSnapshot.docs.map(async (doc) => {
            const agreement = doc.data();
            
            // Fetch the property details
            const propertyDoc = await db.collection('properties').doc(agreement.propertyId).get();
            const propertyName = propertyDoc.exists ? propertyDoc.data().name : 'N/A';

            // Fetch the unit details
            const unitDoc = await db.collection('properties').doc(agreement.propertyId).collection('units').doc(agreement.unitId).get();
            const unitNumber = unitDoc.exists ? unitDoc.data().unitNumber : 'N/A';

            return {
                ...agreement,
                propertyName,
                unitNumber,
            };
        });

        const agreements = await Promise.all(agreementsPromises);

        res.status(200).json(agreements);
    } catch (error) {
        console.error("Error getting tenant agreements:", error);
        res.status(500).json({ error: error.message });
    }
};
