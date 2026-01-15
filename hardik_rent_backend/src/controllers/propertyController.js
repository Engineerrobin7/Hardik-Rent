const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

// Get all properties for an owner
exports.getOwnerProperties = async (req, res) => {
    try {
        const ownerId = req.user.uid;
        const [properties] = await db.query('SELECT * FROM properties WHERE owner_id = ?', [ownerId]);

        // Enhance with units
        for (let prop of properties) {
            const [units] = await db.query('SELECT * FROM units WHERE property_id = ?', [prop.id]);
            prop.units = units;
        }

        res.status(200).json(properties);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Create a new property with building structure
exports.createProperty = async (req, res) => {
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        const ownerId = req.user.uid;
        const { name, address, structure } = req.body;
        const propertyId = uuidv4();

        // 1. Insert Property
        await connection.execute(
            'INSERT INTO properties (id, owner_id, name, address) VALUES (?, ?, ?, ?)',
            [propertyId, ownerId, name, address]
        );

        // 2. Insert Units (from structure floors)
        if (structure && structure.floors) {
            for (let fIndex = 0; fIndex < structure.floors.length; fIndex++) {
                const floor = structure.floors[fIndex];
                if (floor.units) {
                    for (let uIndex = 0; uIndex < floor.units.length; uIndex++) {
                        const unit = floor.units[uIndex];
                        await connection.execute(
                            'INSERT INTO units (id, property_id, floor_number, unit_number, status) VALUES (?, ?, ?, ?, ?)',
                            [uuidv4(), propertyId, fIndex, unit.unit_number || `Unit ${uIndex + 1}`, 'vacant']
                        );
                    }
                }
            }
        }

        await connection.commit();
        res.status(201).json({ id: propertyId, message: 'Property and units created' });
    } catch (error) {
        await connection.rollback();
        res.status(500).json({ error: error.message });
    } finally {
        connection.release();
    }
};

// Update a unit status (FIXED RACE CONDITION USING TRANSACTIONS)
exports.updateUnitStatus = async (req, res) => {
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        const { unitId, status, tenantId } = req.body;

        // Use FOR UPDATE to lock the row during transaction
        const [rows] = await connection.execute(
            'SELECT * FROM units WHERE id = ? FOR UPDATE',
            [unitId]
        );

        if (rows.length === 0) {
            throw new Error('Unit not found');
        }

        const updateQuery = tenantId
            ? 'UPDATE units SET status = ?, tenant_id = ? WHERE id = ?'
            : 'UPDATE units SET status = ? WHERE id = ?';

        const params = tenantId ? [status, tenantId, unitId] : [status, unitId];

        await connection.execute(updateQuery, params);

        await connection.commit();
        res.status(200).json({ message: 'Unit status updated successfully (Atomic Update)' });
    } catch (error) {
        await connection.rollback();
        res.status(500).json({ error: error.message });
    } finally {
        connection.release();
    }
};
