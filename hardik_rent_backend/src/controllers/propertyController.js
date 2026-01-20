const { db } = require('../config/firebaseAdmin');
const { v4: uuidv4 } = require('uuid');

exports.createProperty = async (req, res) => {
    try {
        const { name, address, type } = req.body;
        const ownerId = req.user.uid;

        if (!name || !address || !type) {
            return res.status(400).json({ error: 'Missing required fields: name, address, type' });
        }

        const propertyId = uuidv4();

        const propertyData = {
            id: propertyId,
            ownerId,
            name,
            address,
            type,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
        };

        await db.collection('properties').doc(propertyId).set(propertyData);

        res.status(201).json({
            message: 'Property created successfully',
            propertyId: propertyId,
            data: propertyData
        });
    } catch (error) {
        console.error('Error creating property:', error);
        res.status(500).json({ error: 'Failed to create property' });
    }
};

exports.getOwnerProperties = async (req, res) => {
    try {
        const ownerId = req.user.uid;

        const propertiesSnapshot = await db.collection('properties').where('ownerId', '==', ownerId).get();

        if (propertiesSnapshot.empty) {
            return res.status(200).json([]);
        }

        const properties = [];
        for (const doc of propertiesSnapshot.docs) {
            const property = doc.data();
            const unitsSnapshot = await db.collection('properties').doc(doc.id).collection('units').get();
            property.units = unitsSnapshot.docs.map(unitDoc => unitDoc.data());
            properties.push(property);
        }

        res.status(200).json(properties);
    } catch (error) {
        console.error('Error fetching owner properties:', error);
        res.status(500).json({ error: 'Failed to fetch properties' });
    }
};

exports.createUnit = async (req, res) => {
    try {
        const { propertyId, unitNumber, rent, type } = req.body;
        if (!propertyId || !unitNumber || !rent || !type) {
            return res.status(400).json({ error: 'Missing required fields: propertyId, unitNumber, rent, type' });
        }
        const unitId = uuidv4();

        const unitData = {
            id: unitId,
            propertyId,
            unitNumber,
            rent,
            type,
            status: 'vacant', // vacant, occupied, under_maintenance
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
        };

        await db.collection('properties').doc(propertyId).collection('units').doc(unitId).set(unitData);

        res.status(201).json({
            message: 'Unit created successfully',
            unitId: unitId,
            data: unitData
        });
    } catch (error) {
        console.error('Error creating unit:', error);
        res.status(500).json({ error: 'Failed to create unit' });
    }
};

exports.updateUnitStatus = async (req, res) => {
    try {
        const { propertyId, unitId, status } = req.body;

        if (!propertyId || !unitId || !status) {
            return res.status(400).json({ error: 'Missing required fields: propertyId, unitId, status' });
        }

        const unitRef = db.collection('properties').doc(propertyId).collection('units').doc(unitId);

        await unitRef.update({
            status: status,
            updatedAt: new Date().toISOString(),
        });

        res.status(200).json({ message: 'Unit status updated successfully' });
    } catch (error) {
        console.error('Error updating unit status:', error);
        res.status(500).json({ error: 'Failed to update unit status' });
    }
};


exports.toggleElectricity = async (req, res) => {
    try {
        const { propertyId, unitId, enabled } = req.body;

        if (!propertyId || !unitId || typeof enabled !== 'boolean') {
            return res.status(400).json({ error: 'Missing required fields: propertyId, unitId, enabled (boolean)' });
        }

        const unitRef = db.collection('properties').doc(propertyId).collection('units').doc(unitId);

        await unitRef.update({
            'electricity.enabled': enabled,
            updatedAt: new Date().toISOString(),
        });

        res.status(200).json({ message: `Electricity for unit ${unitId} has been ${enabled ? 'enabled' : 'disabled'}` });
    } catch (error) {
        console.error('Error toggling electricity:', error);
        res.status(500).json({ error: 'Failed to toggle electricity status' });
    }
};