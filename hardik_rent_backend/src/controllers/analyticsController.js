const db = require('../config/db');

exports.getFinancialSummary = async (req, res) => {
    try {
        const ownerId = req.user.uid;

        // 1. Total Potential Revenue (Sum of rent_amount for all occupied units)
        const [revenueRows] = await db.query(`
            SELECT SUM(rent_amount) as totalRevenue 
            FROM units 
            JOIN properties ON units.property_id = properties.id 
            WHERE properties.owner_id = ? AND units.status = 'occupied'
        `, [ownerId]);

        // 2. Occupancy Rate
        const [occupancyRows] = await db.query(`
            SELECT 
                COUNT(*) as totalUnits,
                SUM(CASE WHEN status = 'occupied' THEN 1 ELSE 0 END) as occupiedUnits
            FROM units 
            JOIN properties ON units.property_id = properties.id 
            WHERE properties.owner_id = ?
        `, [ownerId]);

        const totalUnits = occupancyRows[0].totalUnits || 0;
        const occupiedUnits = occupancyRows[0].occupiedUnits || 0;
        const occupancyRate = totalUnits > 0 ? (occupiedUnits / totalUnits) * 100 : 0;

        // 3. Pending Rent (from payments table)
        const [pendingRows] = await db.query(`
            SELECT SUM(amount) as pendingAmount 
            FROM payments 
            JOIN units ON payments.unit_id = units.id
            JOIN properties ON units.property_id = properties.id 
            WHERE properties.owner_id = ? AND payments.status = 'pending'
        `, [ownerId]);

        res.status(200).json({
            totalRevenue: revenueRows[0].totalRevenue || 0,
            occupancyRate: occupancyRate.toFixed(2),
            pendingRent: pendingRows[0].pendingAmount || 0,
            stats: {
                totalUnits,
                occupiedUnits,
                vacantUnits: totalUnits - occupiedUnits
            }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
